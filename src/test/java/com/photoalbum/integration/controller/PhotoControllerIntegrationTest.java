package com.photoalbum.integration.controller;

import com.photoalbum.integration.AbstractPostgreSQLIntegrationTest;
import com.photoalbum.model.Photo;
import com.photoalbum.repository.PhotoRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Integration tests for photo-related controllers using PostgreSQL Testcontainer.
 * Tests verify end-to-end HTTP request handling with a real PostgreSQL database.
 */
@SpringBootTest
@AutoConfigureMockMvc
class PhotoControllerIntegrationTest extends AbstractPostgreSQLIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private PhotoRepository photoRepository;

    private Photo existingPhoto;

    @BeforeEach
    void setUp() throws IOException {
        photoRepository.deleteAll();

        // Create a test photo with real valid image data
        existingPhoto = new Photo();
        existingPhoto.setOriginalFileName("test_photo.jpg");
        existingPhoto.setStoredFileName("stored_test_photo.jpg");
        existingPhoto.setFilePath("/uploads/stored_test_photo.jpg");
        existingPhoto.setMimeType("image/jpeg");
        existingPhoto.setPhotoData(createMinimalValidJpeg());
        existingPhoto.setFileSize((long) existingPhoto.getPhotoData().length);
        existingPhoto.setWidth(10);
        existingPhoto.setHeight(10);
        existingPhoto.setUploadedAt(LocalDateTime.now());
        existingPhoto = photoRepository.save(existingPhoto);
    }

    /**
     * Creates a minimal valid JPEG image using BufferedImage.
     * Following Pattern 3 - create realistic test data, not just magic bytes.
     */
    private byte[] createMinimalValidJpeg() throws IOException {
        BufferedImage image = new BufferedImage(10, 10, BufferedImage.TYPE_INT_RGB);
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        ImageIO.write(image, "jpg", baos);
        return baos.toByteArray();
    }

    @Nested
    @DisplayName("Home Controller - Gallery Page")
    class HomeControllerTests {

        @Test
        @DisplayName("should render gallery page with photos from PostgreSQL")
        void shouldRenderGalleryPageWithPhotos() throws Exception {
            // Act & Assert
            mockMvc.perform(get("/"))
                    .andExpect(status().isOk())
                    .andExpect(view().name("index"))
                    .andExpect(model().attributeExists("photos"))
                    .andExpect(model().attributeExists("timestamp"));
        }

        @Test
        @DisplayName("should render empty gallery when no photos exist")
        void shouldRenderEmptyGallery() throws Exception {
            // Arrange
            photoRepository.deleteAll();

            // Act & Assert
            mockMvc.perform(get("/"))
                    .andExpect(status().isOk())
                    .andExpect(view().name("index"))
                    .andExpect(model().attributeExists("photos"));
        }
    }

    @Nested
    @DisplayName("Home Controller - Photo Upload")
    class PhotoUploadTests {

        @Test
        @DisplayName("should upload photo successfully and store in PostgreSQL")
        void shouldUploadPhotoSuccessfully() throws Exception {
            // Arrange
            byte[] validImageData = createMinimalValidJpeg();
            MockMultipartFile file = new MockMultipartFile(
                    "files",
                    "new_photo.jpg",
                    "image/jpeg",
                    validImageData
            );

            // Act & Assert
            MvcResult result = mockMvc.perform(multipart("/upload").file(file))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true))
                    .andExpect(jsonPath("$.uploadedPhotos").isArray())
                    .andExpect(jsonPath("$.uploadedPhotos[0].id").exists())
                    .andExpect(jsonPath("$.uploadedPhotos[0].originalFileName").value("new_photo.jpg"))
                    .andReturn();

            // Verify photo was saved to PostgreSQL
            long count = photoRepository.count();
            assertThat(count).isEqualTo(2); // existing + new
        }

        @Test
        @DisplayName("should upload multiple photos successfully")
        void shouldUploadMultiplePhotos() throws Exception {
            // Arrange
            byte[] validImageData = createMinimalValidJpeg();
            MockMultipartFile file1 = new MockMultipartFile(
                    "files",
                    "photo1.jpg",
                    "image/jpeg",
                    validImageData
            );
            MockMultipartFile file2 = new MockMultipartFile(
                    "files",
                    "photo2.png",
                    "image/png",
                    createMinimalValidPng()
            );

            // Act & Assert
            mockMvc.perform(multipart("/upload").file(file1).file(file2))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true))
                    .andExpect(jsonPath("$.uploadedPhotos").isArray())
                    .andExpect(jsonPath("$.uploadedPhotos.length()").value(2));

            // Verify photos saved
            long count = photoRepository.count();
            assertThat(count).isEqualTo(3); // 1 existing + 2 new
        }

        @Test
        @DisplayName("should reject unsupported file type")
        void shouldRejectUnsupportedFileType() throws Exception {
            // Arrange
            MockMultipartFile file = new MockMultipartFile(
                    "files",
                    "document.pdf",
                    "application/pdf",
                    "PDF content".getBytes()
            );

            // Act & Assert
            mockMvc.perform(multipart("/upload").file(file))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(false))
                    .andExpect(jsonPath("$.failedUploads").isArray())
                    .andExpect(jsonPath("$.failedUploads[0].error").exists());
        }

        /**
         * Creates a minimal valid PNG image.
         */
        private byte[] createMinimalValidPng() throws IOException {
            BufferedImage image = new BufferedImage(10, 10, BufferedImage.TYPE_INT_RGB);
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            ImageIO.write(image, "png", baos);
            return baos.toByteArray();
        }
    }

    @Nested
    @DisplayName("Photo File Controller - Serving Photos")
    class PhotoFileControllerTests {

        @Test
        @DisplayName("should serve photo binary data from PostgreSQL")
        void shouldServePhotoBinaryData() throws Exception {
            // Act & Assert - Use contentTypeCompatibleWith to ignore charset (Pattern 4)
            mockMvc.perform(get("/photo/{id}", existingPhoto.getId()))
                    .andExpect(status().isOk())
                    .andExpect(content().contentTypeCompatibleWith(MediaType.IMAGE_JPEG))
                    .andExpect(header().string("X-Photo-ID", existingPhoto.getId()))
                    .andExpect(header().string("X-Photo-Name", "test_photo.jpg"))
                    .andExpect(content().bytes(existingPhoto.getPhotoData()));
        }

        @Test
        @DisplayName("should return 404 when photo not found")
        void shouldReturn404WhenPhotoNotFound() throws Exception {
            // Act & Assert
            mockMvc.perform(get("/photo/{id}", "non-existent-id"))
                    .andExpect(status().isNotFound());
        }

        @Test
        @DisplayName("should return 404 for empty photo ID")
        void shouldReturn404ForEmptyId() throws Exception {
            // Act & Assert
            mockMvc.perform(get("/photo/{id}", "   "))
                    .andExpect(status().isNotFound());
        }

        @Test
        @DisplayName("should include cache control headers")
        void shouldIncludeCacheControlHeaders() throws Exception {
            // Act & Assert
            mockMvc.perform(get("/photo/{id}", existingPhoto.getId()))
                    .andExpect(status().isOk())
                    .andExpect(header().string(HttpHeaders.CACHE_CONTROL,
                            "no-cache, no-store, must-revalidate, private"))
                    .andExpect(header().string(HttpHeaders.PRAGMA, "no-cache"))
                    .andExpect(header().string(HttpHeaders.EXPIRES, "0"));
        }
    }
}
