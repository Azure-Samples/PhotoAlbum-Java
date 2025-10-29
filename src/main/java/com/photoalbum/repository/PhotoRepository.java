package com.photoalbum.repository;

import com.photoalbum.model.Photo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Repository interface for Photo entity operations
 */
@Repository
public interface PhotoRepository extends JpaRepository<Photo, String> {

    /**
     * Find all photos ordered by upload date (newest first)
     * @return List of photos ordered by upload date descending
     */
    // Migrated from Oracle to PostgreSQL according to java check item 6: In SQL string literals, use lowercase for identifiers (like table and column names) and data type (like varchar), use uppercase for SQL keywords (like SELECT, FROM, WHERE).
    @Query(value = "SELECT id, original_file_name, photo_data, stored_file_name, file_path, file_size, " +
                   "mime_type, uploaded_at, width, height " +
                   "FROM photos " +
                   "ORDER BY uploaded_at DESC", 
           nativeQuery = true)
    List<Photo> findAllOrderByUploadedAtDesc();

    /**
     * Find photos uploaded before a specific photo (for navigation)
     * @param uploadedAt The upload timestamp to compare against
     * @return List of photos uploaded before the given timestamp
     */
    // Migrated from Oracle to PostgreSQL according to java check item 17: Replace ROWNUM pagination with LIMIT/OFFSET in native SQL queries.
    @Query(value = "SELECT id, original_file_name, photo_data, stored_file_name, file_path, file_size, " +
                   "mime_type, uploaded_at, width, height " +
                   "FROM photos " +
                   "WHERE uploaded_at < :uploadedAt " +
                   "ORDER BY uploaded_at DESC " +
                   "LIMIT 10", 
           nativeQuery = true)
    List<Photo> findPhotosUploadedBefore(@Param("uploadedAt") LocalDateTime uploadedAt);

    /**
     * Find photos uploaded after a specific photo (for navigation)
     * @param uploadedAt The upload timestamp to compare against
     * @return List of photos uploaded after the given timestamp
     */
    // Migrated from Oracle to PostgreSQL according to java check item 6: In SQL string literals, use lowercase for identifiers (like table and column names) and data type (like varchar), use uppercase for SQL keywords (like SELECT, FROM, WHERE).
    @Query(value = "SELECT id, original_file_name, photo_data, stored_file_name, " +
                   "COALESCE(file_path, 'default_path') as file_path, file_size, " +
                   "mime_type, uploaded_at, width, height " +
                   "FROM photos " +
                   "WHERE uploaded_at > :uploadedAt " +
                   "ORDER BY uploaded_at ASC", 
           nativeQuery = true)
    List<Photo> findPhotosUploadedAfter(@Param("uploadedAt") LocalDateTime uploadedAt);

    /**
     * Find photos by upload month using PostgreSQL EXTRACT function - PostgreSQL specific
     * @param year The year to search for
     * @param month The month to search for
     * @return List of photos uploaded in the specified month
     */
    // Migrated from Oracle to PostgreSQL according to java check item 4: Replace TO_CHAR date functions with EXTRACT in SQL statements.
    @Query(value = "SELECT id, original_file_name, photo_data, stored_file_name, file_path, file_size, " +
                   "mime_type, uploaded_at, width, height " +
                   "FROM photos " +
                   "WHERE EXTRACT(YEAR FROM uploaded_at)::text = :year " +
                   "AND LPAD(EXTRACT(MONTH FROM uploaded_at)::text, 2, '0') = :month " +
                   "ORDER BY uploaded_at DESC", 
           nativeQuery = true)
    List<Photo> findPhotosByUploadMonth(@Param("year") String year, @Param("month") String month);

    /**
     * Get paginated photos using PostgreSQL LIMIT/OFFSET - PostgreSQL specific pagination
     * @param pageSize Number of photos per page
     * @param offset Offset for pagination (0-based)
     * @return List of photos within the specified page
     */
    // Migrated from Oracle to PostgreSQL according to java check item 17: Replace ROWNUM pagination with LIMIT/OFFSET in native SQL queries.
    @Query(value = "SELECT id, original_file_name, photo_data, stored_file_name, file_path, file_size, " +
                   "mime_type, uploaded_at, width, height " +
                   "FROM photos ORDER BY uploaded_at DESC " +
                   "LIMIT :pageSize OFFSET :offset", 
           nativeQuery = true)
    List<Photo> findPhotosWithPagination(@Param("pageSize") int pageSize, @Param("offset") int offset);

    /**
     * Find photos with file size statistics using PostgreSQL analytical functions - PostgreSQL specific
     * @return List of photos with running totals and rankings
     */
    // Migrated from Oracle to PostgreSQL according to java check item 3: Replace Oracle-specific SQL functions with PostgreSQL equivalents. Like RANK() to ROW_NUMBER()
    @Query(value = "SELECT id, original_file_name, photo_data, stored_file_name, file_path, file_size, " +
                   "mime_type, uploaded_at, width, height, " +
                   "ROW_NUMBER() OVER (ORDER BY file_size DESC) as size_rank, " +
                   "SUM(file_size) OVER (ORDER BY uploaded_at ROWS UNBOUNDED PRECEDING) as running_total " +
                   "FROM photos " +
                   "ORDER BY uploaded_at DESC", 
           nativeQuery = true)
    List<Object[]> findPhotosWithStatistics();
}