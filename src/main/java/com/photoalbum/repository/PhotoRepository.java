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
     * Migrated from Oracle to PostgreSQL according to java check item 6: In SQL string literals, use lowercase for identifiers (like table and column names) and data type (like varchar), use uppercase for SQL keywords (like SELECT, FROM, WHERE).
     * @return List of photos ordered by upload date descending
     */
    @Query(value = "SELECT id, original_file_name, photo_data, stored_file_name, file_path, file_size, " +
                   "mime_type, uploaded_at, width, height " +
                   "FROM photos " +
                   "ORDER BY uploaded_at DESC",
           nativeQuery = true)
    List<Photo> findAllOrderByUploadedAtDesc();

    /**
     * Migrated from Oracle to PostgreSQL according to java check item 17: Replace ROWNUM pagination with LIMIT/OFFSET in native SQL queries.
     * Migrated from Oracle to PostgreSQL according to java check item 6: In SQL string literals, use lowercase for identifiers (like table and column names) and data type (like varchar), use uppercase for SQL keywords (like SELECT, FROM, WHERE).
     * Find photos uploaded before a specific photo (for navigation)
     * @param uploadedAt The upload timestamp to compare against
     * @return List of photos uploaded before the given timestamp
    @Query(value = "SELECT id, original_file_name, photo_data, stored_file_name, file_path, file_size, " +
                   "mime_type, uploaded_at, width, height " +
                   "FROM photos " +
                   "WHERE uploaded_at < :uploadedAt " +
                   "ORDER BY uploaded_at DESC " +
                   "LIMIT 10",
                   ") WHERE ROWNUM <= 10",
           nativeQuery = true)
    List<Photo> findPhotosUploadedBefore(@Param("uploadedAt") LocalDateTime uploadedAt);

     * Migrated from Oracle to PostgreSQL according to java check item 6: In SQL string literals, use lowercase for identifiers (like table and column names) and data type (like varchar), use uppercase for SQL keywords (like SELECT, FROM, WHERE).
    /**
     * Find photos uploaded after a specific photo (for navigation)
     * @param uploadedAt The upload timestamp to compare against
    @Query(value = "SELECT id, original_file_name, photo_data, stored_file_name, " +
                   "COALESCE(file_path, 'default_path') as file_path, file_size, " +
                   "mime_type, uploaded_at, width, height " +
                   "FROM photos " +
                   "WHERE uploaded_at > :uploadedAt " +
                   "ORDER BY uploaded_at ASC",
                   "WHERE UPLOADED_AT > :uploadedAt " +
                   "ORDER BY UPLOADED_AT ASC", 
           nativeQuery = true)
     * Find photos by upload month - migrated to PostgreSQL
     * Migrated from Oracle to PostgreSQL according to java check item 4: Replace TO_CHAR date functions with EXTRACT in SQL statements.
     * Migrated from Oracle to PostgreSQL according to java check item 6: In SQL string literals, use lowercase for identifiers (like table and column names) and data type (like varchar), use uppercase for SQL keywords (like SELECT, FROM, WHERE).

    /**
     * Find photos by upload month using Oracle TO_CHAR function - Oracle specific
     * @param year The year to search for
    @Query(value = "SELECT id, original_file_name, photo_data, stored_file_name, file_path, file_size, " +
                   "mime_type, uploaded_at, width, height " +
                   "FROM photos " +
                   "WHERE EXTRACT(YEAR FROM uploaded_at)::text = :year " +
                   "AND LPAD(EXTRACT(MONTH FROM uploaded_at)::text, 2, '0') = :month " +
                   "ORDER BY uploaded_at DESC",
                   "WHERE TO_CHAR(UPLOADED_AT, 'YYYY') = :year " +
                   "AND TO_CHAR(UPLOADED_AT, 'MM') = :month " +
     * Get paginated photos - migrated to PostgreSQL
     * Migrated from Oracle to PostgreSQL according to java check item 17: Replace ROWNUM pagination with LIMIT/OFFSET in native SQL queries.
     * Migrated from Oracle to PostgreSQL according to java check item 6: In SQL string literals, use lowercase for identifiers (like table and column names) and data type (like varchar), use uppercase for SQL keywords (like SELECT, FROM, WHERE).
           nativeQuery = true)
    List<Photo> findPhotosByUploadMonth(@Param("year") String year, @Param("month") String month);

    /**
    @Query(value = "SELECT id, original_file_name, photo_data, stored_file_name, file_path, file_size, " +
                   "mime_type, uploaded_at, width, height " +
                   "FROM photos " +
                   "ORDER BY uploaded_at DESC " +
                   "LIMIT :endRow - :startRow + 1 OFFSET :startRow - 1",
                   "SELECT ID, ORIGINAL_FILE_NAME, PHOTO_DATA, STORED_FILE_NAME, FILE_PATH, FILE_SIZE, " +
                   "MIME_TYPE, UPLOADED_AT, WIDTH, HEIGHT " +
                   "FROM PHOTOS ORDER BY UPLOADED_AT DESC" +
                   ") P WHERE ROWNUM <= :endRow" +
     * Find photos with file size statistics - migrated to PostgreSQL
     * Migrated from Oracle to PostgreSQL according to java check item 3: Replace Oracle-specific SQL functions with PostgreSQL equivalents. Like RANK() to ROW_NUMBER()
     * Migrated from Oracle to PostgreSQL according to java check item 6: In SQL string literals, use lowercase for identifiers (like table and column names) and data type (like varchar), use uppercase for SQL keywords (like SELECT, FROM, WHERE).
           nativeQuery = true)
    List<Photo> findPhotosWithPagination(@Param("startRow") int startRow, @Param("endRow") int endRow);
    @Query(value = "SELECT id, original_file_name, photo_data, stored_file_name, file_path, file_size, " +
                   "mime_type, uploaded_at, width, height, " +
                   "ROW_NUMBER() OVER (ORDER BY file_size DESC) as size_rank, " +
                   "SUM(file_size) OVER (ORDER BY uploaded_at ROWS UNBOUNDED PRECEDING) as running_total " +
                   "FROM photos " +
                   "ORDER BY uploaded_at DESC",
                   "MIME_TYPE, UPLOADED_AT, WIDTH, HEIGHT, " +
                   "RANK() OVER (ORDER BY FILE_SIZE DESC) as SIZE_RANK, " +
                   "SUM(FILE_SIZE) OVER (ORDER BY UPLOADED_AT ROWS UNBOUNDED PRECEDING) as RUNNING_TOTAL " +
                   "FROM PHOTOS " +
                   "ORDER BY UPLOADED_AT DESC", 
           nativeQuery = true)
    List<Object[]> findPhotosWithStatistics();
}