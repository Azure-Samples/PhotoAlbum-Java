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
public interface PhotoRepository extends JpaRepository<Photo, Long> {

    /**
     * Find all photos ordered by upload date (newest first)
     * @return List of photos ordered by upload date descending
     */
    @Query(value = "SELECT id, original_file_name, stored_file_name, file_path, file_size, " +
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
    @Query(value = "SELECT id, original_file_name, stored_file_name, file_path, file_size, " +
                   "mime_type, uploaded_at, width, height " +
                   "FROM photos " +
                   "WHERE uploaded_at < :uploadedAt " +
                   "ORDER BY uploaded_at DESC", 
           nativeQuery = true)
    List<Photo> findPhotosUploadedBefore(@Param("uploadedAt") LocalDateTime uploadedAt);

    /**
     * Find photos uploaded after a specific photo (for navigation)
     * @param uploadedAt The upload timestamp to compare against
     * @return List of photos uploaded after the given timestamp
     */
    @Query(value = "SELECT id, original_file_name, stored_file_name, file_path, file_size, " +
                   "mime_type, uploaded_at, width, height " +
                   "FROM photos " +
                   "WHERE uploaded_at > :uploadedAt " +
                   "ORDER BY uploaded_at ASC", 
           nativeQuery = true)
    List<Photo> findPhotosUploadedAfter(@Param("uploadedAt") LocalDateTime uploadedAt);
}