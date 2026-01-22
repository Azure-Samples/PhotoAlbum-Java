package com.photoalbum.integration.service;

import com.photoalbum.integration.AbstractPostgreSQLIntegrationTest;
import com.photoalbum.model.Photo;
import com.photoalbum.model.UploadResult;
import com.photoalbum.repository.PhotoRepository;
import com.photoalbum.service.PhotoService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.mock.web.MockMultipartFile;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Integration tests for PhotoService using PostgreSQL Testcontainer.
 * Tests verify that the service layer works correctly with PostgreSQL,
 * including photo upload with binary storage, retrieval, deletion, and navigation.
 */
@SpringBootTest
class PhotoServiceIntegrationTest extends AbstractPostgreSQLIntegrationTest {

    @Autowired
    private PhotoService photoService;

    @Autowired
    private PhotoRepository photoRepository;

    private Photo existingPhoto1;
    private Photo existingPhoto2;
    private Photo existingPhoto3;

    @BeforeEach
    void setUp() {
        photoRepository.deleteAll();

        // Create existing photos for navigation tests
        existingPhoto1 = createAndSavePhoto("existing1.jpg", "image/jpeg", 1000L,
                LocalDateTime.now().minusDays(3));
        existingPhoto2 = createAndSavePhoto("existing2.png", "image/png", 2000L,
                LocalDateTime.now().minusDays(2));
        existingPhoto3 = createAndSavePhoto("existing3.gif", "image/gif", 3000L,
                LocalDateTime.now().minusDays(1));
    }

    private Photo createAndSavePhoto(String fileName, String mimeType, Long fileSize,
                                      LocalDateTime uploadedAt) {
        Photo photo = new Photo();
        photo.setOriginalFileName(fileName);
        photo.setStoredFileName("stored_" + fileName);
        photo.setFilePath("/uploads/stored_" + fileName);
        photo.setMimeType(mimeType);
        photo.setFileSize(fileSize);
        photo.setPhotoData(createTestPhotoData(fileSize.intValue()));
        photo.setWidth(800);
        photo.setHeight(600);
        photo.setUploadedAt(uploadedAt);
        return photoRepository.save(photo);
    }

    /**
     * Creates test photo data with proper byte casting to avoid lossy conversion errors.
     */
    private byte[] createTestPhotoData(int size) {
        byte[] data = new byte[size];
        for (int i = 0; i < size; i++) {
            data[i] = (byte) (i % 256);
        }
        return data;
    }

    @Nested
    @DisplayName("Get All Photos")
    class GetAllPhotosTests {

        @Test
        @DisplayName("should return all photos ordered by upload date descending")
        void shouldReturnAllPhotosOrderedByUploadDateDesc() {
            // Act
            List<Photo> photos = photoService.getAllPhotos();

            // Assert
            assertThat(photos).hasSize(3);
            assertThat(photos.get(0).getId()).isEqualTo(existingPhoto3.getId());
            assertThat(photos.get(1).getId()).isEqualTo(existingPhoto2.getId());
            assertThat(photos.get(2).getId()).isEqualTo(existingPhoto1.getId());
        }

        @Test
        @DisplayName("should return empty list when no photos exist")
        void shouldReturnEmptyListWhenNoPhotosExist() {
            // Arrange
            photoRepository.deleteAll();

            // Act
            List<Photo> photos = photoService.getAllPhotos();

            // Assert
            assertThat(photos).isEmpty();
        }
    }

    @Nested
    @DisplayName("Get Photo By ID")
    class GetPhotoByIdTests {

        @Test
        @DisplayName("should return photo when ID exists")
        void shouldReturnPhotoWhenIdExists() {
            // Act
            Optional<Photo> result = photoService.getPhotoById(existingPhoto1.getId());

            // Assert
            assertThat(result).isPresent();
            assertThat(result.get().getOriginalFileName()).isEqualTo("existing1.jpg");
        }

        @Test
        @DisplayName("should return empty when ID does not exist")
        void shouldReturnEmptyWhenIdDoesNotExist() {
            // Act
            Optional<Photo> result = photoService.getPhotoById("non-existent-id");

            // Assert
            assertThat(result).isEmpty();
        }
    }

    @Nested
    @DisplayName("Upload Photo")
    class UploadPhotoTests {

        @Test
        @DisplayName("should upload JPEG photo successfully to PostgreSQL")
        void shouldUploadJpegPhotoSuccessfully() throws IOException {
            // Arrange - Create minimal valid JPEG image
            byte[] jpegData = createMinimalValidJpeg();
            MockMultipartFile file = new MockMultipartFile(
                    "file",
                    "test_upload.jpg",
                    "image/jpeg",
                    jpegData
            );

            // Act
            UploadResult result = photoService.uploadPhoto(file);

            // Assert
            assertThat(result.isSuccess())
                .as("Upload should succeed. Error: %s", result.getErrorMessage())
                .isTrue();
            assertThat(result.getPhotoId()).isNotNull();
            assertThat(result.getErrorMessage()).isNull();

            // Verify photo was saved to PostgreSQL
            Optional<Photo> savedPhoto = photoRepository.findById(result.getPhotoId());
            assertThat(savedPhoto).isPresent();
            assertThat(savedPhoto.get().getOriginalFileName()).isEqualTo("test_upload.jpg");
            assertThat(savedPhoto.get().getMimeType()).isEqualTo("image/jpeg");
            assertThat(savedPhoto.get().getPhotoData()).hasSize(jpegData.length);
        }

        @Test
        @DisplayName("should upload PNG photo successfully")
        void shouldUploadPngPhotoSuccessfully() throws IOException {
            // Arrange - Create minimal valid PNG image
            byte[] pngData = createMinimalValidPng();
            MockMultipartFile file = new MockMultipartFile(
                    "file",
                    "test_upload.png",
                    "image/png",
                    pngData
            );

            // Act
            UploadResult result = photoService.uploadPhoto(file);

            // Assert
            assertThat(result.isSuccess())
                .as("Upload should succeed. Error: %s", result.getErrorMessage())
                .isTrue();
            assertThat(result.getPhotoId()).isNotNull();
        }

        @Test
        @DisplayName("should reject unsupported file type")
        void shouldRejectUnsupportedFileType() {
            // Arrange
            MockMultipartFile file = new MockMultipartFile(
                    "file",
                    "document.pdf",
                    "application/pdf",
                    "PDF content".getBytes()
            );

            // Act
            UploadResult result = photoService.uploadPhoto(file);

            // Assert
            assertThat(result.isSuccess()).isFalse();
            assertThat(result.getErrorMessage()).contains("not supported");
        }

        @Test
        @DisplayName("should reject file exceeding size limit")
        void shouldRejectFileTooLarge() {
            // Arrange - Create 11MB file (exceeds 10MB limit)
            byte[] largeData = new byte[11 * 1024 * 1024];
            MockMultipartFile file = new MockMultipartFile(
                    "file",
                    "huge_photo.jpg",
                    "image/jpeg",
                    largeData
            );

            // Act
            UploadResult result = photoService.uploadPhoto(file);

            // Assert
            assertThat(result.isSuccess()).isFalse();
            assertThat(result.getErrorMessage()).contains("exceeds");
        }

        @Test
        @DisplayName("should reject empty file")
        void shouldRejectEmptyFile() {
            // Arrange
            MockMultipartFile file = new MockMultipartFile(
                    "file",
                    "empty.jpg",
                    "image/jpeg",
                    new byte[0]
            );

            // Act
            UploadResult result = photoService.uploadPhoto(file);

            // Assert
            assertThat(result.isSuccess()).isFalse();
            assertThat(result.getErrorMessage()).contains("empty");
        }

        /**
         * Creates a minimal valid JPEG image using BufferedImage.
         * Following Pattern 3 best practice - create realistic test data.
         */
        private byte[] createMinimalValidJpeg() throws IOException {
            BufferedImage image = new BufferedImage(10, 10, BufferedImage.TYPE_INT_RGB);
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            ImageIO.write(image, "jpg", baos);
            return baos.toByteArray();
        }

        /**
         * Creates a minimal valid PNG image using BufferedImage.
         */
        private byte[] createMinimalValidPng() throws IOException {
            BufferedImage image = new BufferedImage(10, 10, BufferedImage.TYPE_INT_RGB);
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            ImageIO.write(image, "png", baos);
            return baos.toByteArray();
        }
    }

    @Nested
    @DisplayName("Delete Photo")
    class DeletePhotoTests {

        @Test
        @DisplayName("should delete existing photo from PostgreSQL")
        void shouldDeleteExistingPhoto() {
            // Arrange
            String photoId = existingPhoto1.getId();

            // Act
            boolean result = photoService.deletePhoto(photoId);

            // Assert
            assertThat(result).isTrue();
            assertThat(photoRepository.findById(photoId)).isEmpty();
        }

        @Test
        @DisplayName("should return false when deleting non-existent photo")
        void shouldReturnFalseWhenDeletingNonExistentPhoto() {
            // Act
            boolean result = photoService.deletePhoto("non-existent-id");

            // Assert
            assertThat(result).isFalse();
        }
    }

    @Nested
    @DisplayName("Photo Navigation")
    class PhotoNavigationTests {

        @Test
        @DisplayName("should return previous (older) photo")
        void shouldReturnPreviousPhoto() {
            // Act
            Optional<Photo> previous = photoService.getPreviousPhoto(existingPhoto3);

            // Assert
            assertThat(previous).isPresent();
            assertThat(previous.get().getId()).isEqualTo(existingPhoto2.getId());
        }

        @Test
        @DisplayName("should return next (newer) photo")
        void shouldReturnNextPhoto() {
            // Act
            Optional<Photo> next = photoService.getNextPhoto(existingPhoto1);

            // Assert
            assertThat(next).isPresent();
            assertThat(next.get().getId()).isEqualTo(existingPhoto2.getId());
        }

        @Test
        @DisplayName("should return empty when no previous photo exists")
        void shouldReturnEmptyWhenNoPreviousPhoto() {
            // Act
            Optional<Photo> previous = photoService.getPreviousPhoto(existingPhoto1);

            // Assert
            assertThat(previous).isEmpty();
        }

        @Test
        @DisplayName("should return empty when no next photo exists")
        void shouldReturnEmptyWhenNoNextPhoto() {
            // Act
            Optional<Photo> next = photoService.getNextPhoto(existingPhoto3);

            // Assert
            assertThat(next).isEmpty();
        }
    }
}
