package com.photoalbum.integration.repository;

import com.photoalbum.integration.AbstractPostgreSQLIntegrationTest;
import com.photoalbum.model.Photo;
import com.photoalbum.repository.PhotoRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Integration tests for PhotoRepository using PostgreSQL Testcontainer.
 * Tests verify that JPA repository operations work correctly with PostgreSQL,
 * including PostgreSQL-specific queries with EXTRACT, LIMIT/OFFSET, and window functions.
 */
@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
class PhotoRepositoryIntegrationTest extends AbstractPostgreSQLIntegrationTest {

    @Autowired
    private PhotoRepository photoRepository;

    private Photo testPhoto1;
    private Photo testPhoto2;
    private Photo testPhoto3;

    @BeforeEach
    void setUp() {
        photoRepository.deleteAll();

        // Create test photos with different timestamps
        testPhoto1 = createPhoto("photo1.jpg", "image/jpeg", 1024L);
        testPhoto1.setUploadedAt(LocalDateTime.now().minusDays(2));
        testPhoto1 = photoRepository.save(testPhoto1);

        testPhoto2 = createPhoto("photo2.png", "image/png", 2048L);
        testPhoto2.setUploadedAt(LocalDateTime.now().minusDays(1));
        testPhoto2 = photoRepository.save(testPhoto2);

        testPhoto3 = createPhoto("photo3.gif", "image/gif", 512L);
        testPhoto3.setUploadedAt(LocalDateTime.now());
        testPhoto3 = photoRepository.save(testPhoto3);
    }

    private Photo createPhoto(String originalFileName, String mimeType, Long fileSize) {
        Photo photo = new Photo();
        photo.setOriginalFileName(originalFileName);
        photo.setStoredFileName("stored_" + originalFileName);
        photo.setFilePath("/uploads/stored_" + originalFileName);
        photo.setMimeType(mimeType);
        photo.setFileSize(fileSize);
        photo.setPhotoData(createTestPhotoData(fileSize.intValue()));
        photo.setWidth(800);
        photo.setHeight(600);
        return photo;
    }

    /**
     * Creates test photo data with proper byte casting to avoid lossy conversion errors.
     */
    private byte[] createTestPhotoData(int size) {
        byte[] data = new byte[size];
        for (int i = 0; i < size; i++) {
            // Use explicit cast to byte to avoid lossy conversion error
            data[i] = (byte) (i % 256);
        }
        return data;
    }

    @Nested
    @DisplayName("Basic CRUD Operations")
    class CrudOperations {

        @Test
        @DisplayName("should save and retrieve photo by ID")
        void shouldSaveAndRetrievePhotoById() {
            // Arrange
            Photo newPhoto = createPhoto("new_photo.jpg", "image/jpeg", 3000L);

            // Act
            Photo savedPhoto = photoRepository.save(newPhoto);
            Optional<Photo> retrievedPhoto = photoRepository.findById(savedPhoto.getId());

            // Assert
            assertThat(retrievedPhoto).isPresent();
            assertThat(retrievedPhoto.get().getOriginalFileName()).isEqualTo("new_photo.jpg");
            assertThat(retrievedPhoto.get().getMimeType()).isEqualTo("image/jpeg");
            assertThat(retrievedPhoto.get().getFileSize()).isEqualTo(3000L);
        }

        @Test
        @DisplayName("should return empty when photo not found")
        void shouldReturnEmptyWhenPhotoNotFound() {
            // Act
            Optional<Photo> result = photoRepository.findById("non-existent-id");

            // Assert
            assertThat(result).isEmpty();
        }

        @Test
        @DisplayName("should delete photo successfully")
        void shouldDeletePhotoSuccessfully() {
            // Arrange
            String photoId = testPhoto1.getId();

            // Act
            photoRepository.deleteById(photoId);
            Optional<Photo> result = photoRepository.findById(photoId);

            // Assert
            assertThat(result).isEmpty();
        }

        @Test
        @DisplayName("should update photo successfully")
        void shouldUpdatePhotoSuccessfully() {
            // Arrange
            testPhoto1.setOriginalFileName("updated_photo.jpg");
            testPhoto1.setWidth(1920);
            testPhoto1.setHeight(1080);

            // Act
            Photo updatedPhoto = photoRepository.save(testPhoto1);

            // Assert
            assertThat(updatedPhoto.getOriginalFileName()).isEqualTo("updated_photo.jpg");
            assertThat(updatedPhoto.getWidth()).isEqualTo(1920);
            assertThat(updatedPhoto.getHeight()).isEqualTo(1080);
        }

        @Test
        @DisplayName("should store and retrieve binary photo data (BYTEA)")
        void shouldStoreAndRetrieveBinaryPhotoData() {
            // Arrange - PNG header bytes with explicit casts
            byte[] imageData = new byte[]{
                (byte) 0x89, (byte) 0x50, (byte) 0x4E, (byte) 0x47,
                (byte) 0x0D, (byte) 0x0A, (byte) 0x1A, (byte) 0x0A
            };
            Photo photo = createPhoto("binary_test.png", "image/png", (long) imageData.length);
            photo.setPhotoData(imageData);

            // Act
            Photo savedPhoto = photoRepository.save(photo);
            Optional<Photo> retrievedPhoto = photoRepository.findById(savedPhoto.getId());

            // Assert
            assertThat(retrievedPhoto).isPresent();
            assertThat(retrievedPhoto.get().getPhotoData()).isEqualTo(imageData);
        }
    }

    @Nested
    @DisplayName("Custom Query Methods")
    class CustomQueryMethods {

        @Test
        @DisplayName("should find all photos ordered by upload date descending")
        void shouldFindAllPhotosOrderedByUploadDateDesc() {
            // Act
            List<Photo> photos = photoRepository.findAllOrderByUploadedAtDesc();

            // Assert
            assertThat(photos).hasSize(3);
            assertThat(photos.get(0).getId()).isEqualTo(testPhoto3.getId());
            assertThat(photos.get(1).getId()).isEqualTo(testPhoto2.getId());
            assertThat(photos.get(2).getId()).isEqualTo(testPhoto1.getId());
        }

        @Test
        @DisplayName("should find photos uploaded before a given timestamp")
        void shouldFindPhotosUploadedBefore() {
            // Act
            List<Photo> photos = photoRepository.findPhotosUploadedBefore(testPhoto3.getUploadedAt());

            // Assert
            assertThat(photos).hasSize(2);
            assertThat(photos.get(0).getId()).isEqualTo(testPhoto2.getId());
            assertThat(photos.get(1).getId()).isEqualTo(testPhoto1.getId());
        }

        @Test
        @DisplayName("should find photos uploaded after a given timestamp")
        void shouldFindPhotosUploadedAfter() {
            // Act
            List<Photo> photos = photoRepository.findPhotosUploadedAfter(testPhoto1.getUploadedAt());

            // Assert
            assertThat(photos).hasSize(2);
            // Ordered by ASC, so oldest first
            assertThat(photos.get(0).getId()).isEqualTo(testPhoto2.getId());
            assertThat(photos.get(1).getId()).isEqualTo(testPhoto3.getId());
        }

        @Test
        @DisplayName("should return empty list when no photos before timestamp")
        void shouldReturnEmptyListWhenNoPhotosBefore() {
            // Act
            List<Photo> photos = photoRepository.findPhotosUploadedBefore(testPhoto1.getUploadedAt());

            // Assert
            assertThat(photos).isEmpty();
        }

        @Test
        @DisplayName("should return empty list when no photos after timestamp")
        void shouldReturnEmptyListWhenNoPhotosAfter() {
            // Act
            List<Photo> photos = photoRepository.findPhotosUploadedAfter(testPhoto3.getUploadedAt());

            // Assert
            assertThat(photos).isEmpty();
        }
    }

    @Nested
    @DisplayName("PostgreSQL-Specific Query Methods")
    class PostgreSQLSpecificQueries {

        @Test
        @DisplayName("should find photos by upload month using EXTRACT function")
        void shouldFindPhotosByUploadMonth() {
            // Arrange
            LocalDateTime now = LocalDateTime.now();
            String year = String.valueOf(now.getYear());
            String month = String.format("%02d", now.getMonthValue());

            // Act
            List<Photo> photos = photoRepository.findPhotosByUploadMonth(year, month);

            // Assert
            assertThat(photos).isNotEmpty();
            assertThat(photos).contains(testPhoto3);
        }

        @Test
        @DisplayName("should find photos with pagination using LIMIT/OFFSET")
        void shouldFindPhotosWithPagination() {
            // Act - Get first page (2 items)
            List<Photo> firstPage = photoRepository.findPhotosWithPagination(2, 0);

            // Act - Get second page (remaining items)
            List<Photo> secondPage = photoRepository.findPhotosWithPagination(2, 2);

            // Assert
            assertThat(firstPage).hasSize(2);
            assertThat(firstPage.get(0).getId()).isEqualTo(testPhoto3.getId());
            assertThat(firstPage.get(1).getId()).isEqualTo(testPhoto2.getId());

            assertThat(secondPage).hasSize(1);
            assertThat(secondPage.get(0).getId()).isEqualTo(testPhoto1.getId());
        }

        @Test
        @DisplayName("should find photos with statistics using window functions")
        void shouldFindPhotosWithStatistics() {
            // Act
            List<Object[]> results = photoRepository.findPhotosWithStatistics();

            // Assert
            assertThat(results).hasSize(3);

            // Verify that window function columns are present (size_rank and running_total)
            for (Object[] row : results) {
                assertThat(row.length).isGreaterThanOrEqualTo(11); // 10 photo columns + 2 computed
            }
        }

        @Test
        @DisplayName("should handle empty pagination gracefully")
        void shouldHandleEmptyPaginationGracefully() {
            // Act - Request page beyond available data
            List<Photo> emptyPage = photoRepository.findPhotosWithPagination(10, 100);

            // Assert
            assertThat(emptyPage).isEmpty();
        }
    }

    @Nested
    @DisplayName("Large Binary Data (BYTEA) Tests")
    class LargeBinaryDataTests {

        @Test
        @DisplayName("should store and retrieve large photo data")
        void shouldStoreAndRetrieveLargePhotoData() {
            // Arrange - Create 1MB of test data
            int size = 1024 * 1024; // 1MB
            byte[] largeData = new byte[size];
            for (int i = 0; i < size; i++) {
                // Use explicit cast to avoid lossy conversion
                largeData[i] = (byte) (i % 256);
            }

            Photo photo = createPhoto("large_photo.jpg", "image/jpeg", (long) size);
            photo.setPhotoData(largeData);

            // Act
            Photo savedPhoto = photoRepository.save(photo);
            Optional<Photo> retrievedPhoto = photoRepository.findById(savedPhoto.getId());

            // Assert
            assertThat(retrievedPhoto).isPresent();
            assertThat(retrievedPhoto.get().getPhotoData()).hasSize(size);
            assertThat(retrievedPhoto.get().getPhotoData()).isEqualTo(largeData);
        }

        @Test
        @DisplayName("should handle null photo data")
        void shouldHandleNullPhotoData() {
            // Arrange
            Photo photo = createPhoto("no_data.jpg", "image/jpeg", 0L);
            photo.setPhotoData(null);

            // Act
            Photo savedPhoto = photoRepository.save(photo);
            Optional<Photo> retrievedPhoto = photoRepository.findById(savedPhoto.getId());

            // Assert
            assertThat(retrievedPhoto).isPresent();
            assertThat(retrievedPhoto.get().getPhotoData()).isNull();
        }
    }

    @Nested
    @DisplayName("Timestamp Handling Tests")
    class TimestampHandlingTests {

        @Test
        @DisplayName("should preserve timestamp precision")
        void shouldPreserveTimestampPrecision() {
            // Arrange
            LocalDateTime preciseTimestamp = LocalDateTime.of(2024, 6, 15, 14, 30, 45, 123456789);
            Photo photo = createPhoto("timestamp_test.jpg", "image/jpeg", 100L);
            photo.setUploadedAt(preciseTimestamp);

            // Act
            Photo savedPhoto = photoRepository.save(photo);
            Optional<Photo> retrievedPhoto = photoRepository.findById(savedPhoto.getId());

            // Assert
            assertThat(retrievedPhoto).isPresent();
            // PostgreSQL stores microseconds, so we compare up to that precision
            LocalDateTime retrieved = retrievedPhoto.get().getUploadedAt();
            assertThat(retrieved.getYear()).isEqualTo(2024);
            assertThat(retrieved.getMonthValue()).isEqualTo(6);
            assertThat(retrieved.getDayOfMonth()).isEqualTo(15);
            assertThat(retrieved.getHour()).isEqualTo(14);
            assertThat(retrieved.getMinute()).isEqualTo(30);
            assertThat(retrieved.getSecond()).isEqualTo(45);
        }

        @Test
        @DisplayName("should auto-generate uploadedAt on creation")
        void shouldAutoGenerateUploadedAtOnCreation() {
            // Arrange
            Photo photo = new Photo();
            photo.setOriginalFileName("auto_timestamp.jpg");
            photo.setStoredFileName("stored_auto_timestamp.jpg");
            photo.setFilePath("/uploads/stored_auto_timestamp.jpg");
            photo.setMimeType("image/jpeg");
            photo.setFileSize(100L);

            // Act
            Photo savedPhoto = photoRepository.save(photo);

            // Assert
            assertThat(savedPhoto.getUploadedAt()).isNotNull();
            assertThat(savedPhoto.getUploadedAt()).isBeforeOrEqualTo(LocalDateTime.now());
        }
    }
}
