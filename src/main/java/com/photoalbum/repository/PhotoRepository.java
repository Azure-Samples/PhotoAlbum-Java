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
    @Query(value = "SELECT ID, ORIGINAL_FILE_NAME, PHOTO_DATA, FILE_SIZE, " +
                   "MIME_TYPE, UPLOADED_AT, WIDTH, HEIGHT " +
                   "FROM PHOTOS " +
                   "ORDER BY UPLOADED_AT DESC", 
           nativeQuery = true)
    List<Photo> findAllOrderByUploadedAtDesc();

    /**
     * Find photos uploaded before a specific photo (for navigation)
     * @param uploadedAt The upload timestamp to compare against
     * @return List of photos uploaded before the given timestamp
     */
    @Query(value = "SELECT ID, ORIGINAL_FILE_NAME, PHOTO_DATA, FILE_SIZE, " +
                   "MIME_TYPE, UPLOADED_AT, WIDTH, HEIGHT " +
                   "FROM PHOTOS " +
                   "WHERE UPLOADED_AT < :uploadedAt " +
                   "ORDER BY UPLOADED_AT DESC " +
                   "LIMIT 10", 
           nativeQuery = true)
    List<Photo> findPhotosUploadedBefore(@Param("uploadedAt") LocalDateTime uploadedAt);

    /**
     * Find photos uploaded after a specific photo (for navigation)
     * @param uploadedAt The upload timestamp to compare against
     * @return List of photos uploaded after the given timestamp
     */
    @Query(value = "SELECT ID, ORIGINAL_FILE_NAME, PHOTO_DATA, FILE_SIZE, " +
                   "MIME_TYPE, UPLOADED_AT, WIDTH, HEIGHT " +
                   "FROM PHOTOS " +
                   "WHERE UPLOADED_AT > :uploadedAt " +
                   "ORDER BY UPLOADED_AT ASC", 
           nativeQuery = true)
    List<Photo> findPhotosUploadedAfter(@Param("uploadedAt") LocalDateTime uploadedAt);
}