package com.photoalbum.dao;

import com.photoalbum.model.Photo;
import com.photoalbum.util.DatabaseConfig;

import java.sql.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Data Access Object for Photo entity using pure JDBC
 * Handles all database operations for photos stored in Oracle database
 */
public class PhotoDAO {

    /**
     * Get database connection from configuration
     */
    private Connection getConnection() throws SQLException {
        return DatabaseConfig.getConnection();
    }

    /**
     * Save a new photo to the database
     */
    public Photo save(Photo photo) throws SQLException {
        String sql = "INSERT INTO photos (id, original_file_name, photo_data, stored_file_name, " +
                    "file_path, file_size, mime_type, uploaded_at, width, height) " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            // Generate ID if not set
            if (photo.getId() == null || photo.getId().isEmpty()) {
                photo.setId(UUID.randomUUID().toString());
            }

            // Set uploaded time if not set
            if (photo.getUploadedAt() == null) {
                photo.setUploadedAt(LocalDateTime.now());
            }

            stmt.setString(1, photo.getId());
            stmt.setString(2, photo.getOriginalFileName());
            stmt.setBytes(3, photo.getPhotoData());
            stmt.setString(4, photo.getStoredFileName());
            stmt.setString(5, photo.getFilePath());
            stmt.setLong(6, photo.getFileSize());
            stmt.setString(7, photo.getMimeType());
            stmt.setTimestamp(8, Timestamp.valueOf(photo.getUploadedAt()));

            // Set width and height (can be null)
            if (photo.getWidth() != null) {
                stmt.setInt(9, photo.getWidth());
            } else {
                stmt.setNull(9, Types.INTEGER);
            }

            if (photo.getHeight() != null) {
                stmt.setInt(10, photo.getHeight());
            } else {
                stmt.setNull(10, Types.INTEGER);
            }

            stmt.executeUpdate();
            return photo;
        }
    }

    /**
     * Find a photo by ID
     */
    public Photo findById(String id) throws SQLException {
        String sql = "SELECT id, original_file_name, photo_data, stored_file_name, file_path, " +
                    "file_size, mime_type, uploaded_at, width, height FROM photos WHERE id = ?";

        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, id);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToPhoto(rs);
                }
            }
        }

        return null;
    }

    /**
     * Find all photos, ordered by upload date (newest first)
     */
    public List<Photo> findAll() throws SQLException {
        String sql = "SELECT id, original_file_name, photo_data, stored_file_name, file_path, " +
                    "file_size, mime_type, uploaded_at, width, height FROM photos " +
                    "ORDER BY uploaded_at DESC";

        List<Photo> photos = new ArrayList<>();

        try (Connection conn = getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {

            while (rs.next()) {
                photos.add(mapResultSetToPhoto(rs));
            }
        }

        return photos;
    }

    /**
     * Find all photos with pagination
     */
    public List<Photo> findAll(int offset, int limit) throws SQLException {
        String sql = "SELECT id, original_file_name, photo_data, stored_file_name, file_path, " +
                    "file_size, mime_type, uploaded_at, width, height FROM photos " +
                    "ORDER BY uploaded_at DESC " +
                    "OFFSET ? ROWS FETCH NEXT ? ROWS ONLY";

        List<Photo> photos = new ArrayList<>();

        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, offset);
            stmt.setInt(2, limit);

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    photos.add(mapResultSetToPhoto(rs));
                }
            }
        }

        return photos;
    }

    /**
     * Count total number of photos
     */
    public long count() throws SQLException {
        String sql = "SELECT COUNT(*) FROM photos";

        try (Connection conn = getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {

            if (rs.next()) {
                return rs.getLong(1);
            }
        }

        return 0;
    }

    /**
     * Delete a photo by ID
     */
    public boolean deleteById(String id) throws SQLException {
        String sql = "DELETE FROM photos WHERE id = ?";

        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, id);
            int rowsAffected = stmt.executeUpdate();

            return rowsAffected > 0;
        }
    }

    /**
     * Update photo metadata (width, height)
     */
    public boolean updateMetadata(String id, Integer width, Integer height) throws SQLException {
        String sql = "UPDATE photos SET width = ?, height = ? WHERE id = ?";

        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            if (width != null) {
                stmt.setInt(1, width);
            } else {
                stmt.setNull(1, Types.INTEGER);
            }

            if (height != null) {
                stmt.setInt(2, height);
            } else {
                stmt.setNull(2, Types.INTEGER);
            }

            stmt.setString(3, id);

            int rowsAffected = stmt.executeUpdate();
            return rowsAffected > 0;
        }
    }

    /**
     * Check if a photo exists by ID
     */
    public boolean exists(String id) throws SQLException {
        String sql = "SELECT 1 FROM photos WHERE id = ?";

        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, id);

            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next();
            }
        }
    }

    /**
     * Helper method to map ResultSet to Photo object
     */
    private Photo mapResultSetToPhoto(ResultSet rs) throws SQLException {
        Photo photo = new Photo();

        photo.setId(rs.getString("id"));
        photo.setOriginalFileName(rs.getString("original_file_name"));
        photo.setPhotoData(rs.getBytes("photo_data"));
        photo.setStoredFileName(rs.getString("stored_file_name"));
        photo.setFilePath(rs.getString("file_path"));
        photo.setFileSize(rs.getLong("file_size"));
        photo.setMimeType(rs.getString("mime_type"));

        Timestamp uploadedAt = rs.getTimestamp("uploaded_at");
        if (uploadedAt != null) {
            photo.setUploadedAt(uploadedAt.toLocalDateTime());
        }

        int width = rs.getInt("width");
        if (!rs.wasNull()) {
            photo.setWidth(width);
        }

        int height = rs.getInt("height");
        if (!rs.wasNull()) {
            photo.setHeight(height);
        }

        return photo;
    }

    /**
     * Delete all photos (use with caution!)
     */
    public int deleteAll() throws SQLException {
        String sql = "DELETE FROM photos";

        try (Connection conn = getConnection();
             Statement stmt = conn.createStatement()) {

            return stmt.executeUpdate(sql);
        }
    }
}
