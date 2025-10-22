package com.photoalbum.repository;

import com.photoalbum.model.Photo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

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
    @Query("SELECT p FROM Photo p ORDER BY p.uploadedAt DESC")
    List<Photo> findAllOrderByUploadedAtDesc();

    /**
     * Find photos uploaded before a specific photo (for navigation)
     * @param uploadedAt The upload timestamp to compare against
     * @return List of photos uploaded before the given timestamp
     */
    @Query("SELECT p FROM Photo p WHERE p.uploadedAt < :uploadedAt ORDER BY p.uploadedAt DESC")
    List<Photo> findPhotosUploadedBefore(java.time.LocalDateTime uploadedAt);

    /**
     * Find photos uploaded after a specific photo (for navigation)
     * @param uploadedAt The upload timestamp to compare against
     * @return List of photos uploaded after the given timestamp
     */
    @Query("SELECT p FROM Photo p WHERE p.uploadedAt > :uploadedAt ORDER BY p.uploadedAt ASC")
    List<Photo> findPhotosUploadedAfter(java.time.LocalDateTime uploadedAt);
}