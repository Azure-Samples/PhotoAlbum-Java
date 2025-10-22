package com.photoalbum.service.impl;

import com.photoalbum.model.Photo;
import com.photoalbum.model.UploadResult;
import com.photoalbum.repository.PhotoRepository;
import com.photoalbum.service.PhotoService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Service implementation for photo operations including upload, retrieval, and deletion
 */
@Service
@Transactional
public class PhotoServiceImpl implements PhotoService {

    private static final Logger logger = LoggerFactory.getLogger(PhotoServiceImpl.class);

    private final PhotoRepository photoRepository;
    private final String uploadPath;
    private final long maxFileSizeBytes;
    private final List<String> allowedMimeTypes;

    public PhotoServiceImpl(
            PhotoRepository photoRepository,
            @Value("${app.file-upload.upload-path}") String uploadPath,
            @Value("${app.file-upload.max-file-size-bytes}") long maxFileSizeBytes,
            @Value("${app.file-upload.allowed-mime-types}") String[] allowedMimeTypes) {
        this.photoRepository = photoRepository;
        this.uploadPath = uploadPath;
        this.maxFileSizeBytes = maxFileSizeBytes;
        this.allowedMimeTypes = Arrays.asList(allowedMimeTypes);
    }

    /**
     * Get all photos ordered by upload date (newest first)
     */
    @Override
    @Transactional(readOnly = true)
    public List<Photo> getAllPhotos() {
        try {
            return photoRepository.findAllOrderByUploadedAtDesc();
        } catch (Exception ex) {
            logger.error("Error retrieving photos from database", ex);
            throw new RuntimeException("Error retrieving photos", ex);
        }
    }

    /**
     * Get a specific photo by ID
     */
    @Override
    @Transactional(readOnly = true)
    public Optional<Photo> getPhotoById(Long id) {
        try {
            return photoRepository.findById(id);
        } catch (Exception ex) {
            logger.error("Error retrieving photo with ID {}", id, ex);
            throw new RuntimeException("Error retrieving photo", ex);
        }
    }

    /**
     * Upload a photo file
     */
    @Override
    public UploadResult uploadPhoto(MultipartFile file) {
        UploadResult result = new UploadResult();
        result.setFileName(file.getOriginalFilename());

        try {
            // Validate file type
            if (!allowedMimeTypes.contains(file.getContentType().toLowerCase())) {
                result.setSuccess(false);
                result.setErrorMessage("File type not supported. Please upload JPEG, PNG, GIF, or WebP images.");
                logger.warn("Upload rejected: Invalid file type {} for {}", 
                    file.getContentType(), file.getOriginalFilename());
                return result;
            }

            // Validate file size
            if (file.getSize() > maxFileSizeBytes) {
                result.setSuccess(false);
                result.setErrorMessage(String.format("File size exceeds %dMB limit.", maxFileSizeBytes / 1024 / 1024));
                logger.warn("Upload rejected: File size {} exceeds limit for {}", 
                    file.getSize(), file.getOriginalFilename());
                return result;
            }

            // Validate file length
            if (file.getSize() <= 0) {
                result.setSuccess(false);
                result.setErrorMessage("File is empty.");
                return result;
            }

            // Generate unique filename
            String extension = getFileExtension(file.getOriginalFilename());
            String storedFileName = UUID.randomUUID().toString() + extension;
            String relativePath = "/uploads/" + storedFileName;

            // Ensure upload directory exists
            Path uploadDir = Paths.get(uploadPath);
            if (!Files.exists(uploadDir)) {
                Files.createDirectories(uploadDir);
            }

            Path fullPath = uploadDir.resolve(storedFileName);

            // Extract image dimensions
            Integer width = null;
            Integer height = null;
            try {
                BufferedImage image = ImageIO.read(file.getInputStream());
                if (image != null) {
                    width = image.getWidth();
                    height = image.getHeight();
                }
            } catch (Exception ex) {
                logger.warn("Could not extract image dimensions for {}", file.getOriginalFilename(), ex);
                // Continue without dimensions - not critical
            }

            // Save file to disk
            try {
                Files.copy(file.getInputStream(), fullPath, StandardCopyOption.REPLACE_EXISTING);
            } catch (Exception ex) {
                logger.error("Error saving file {} to {}", file.getOriginalFilename(), fullPath, ex);
                result.setSuccess(false);
                result.setErrorMessage("Error saving file. Please try again.");
                return result;
            }

            // Create photo entity
            Photo photo = new Photo(
                file.getOriginalFilename(),
                storedFileName,
                relativePath,
                file.getSize(),
                file.getContentType()
            );
            photo.setWidth(width);
            photo.setHeight(height);

            // Save to database
            try {
                photo = photoRepository.save(photo);

                result.setSuccess(true);
                result.setPhotoId(photo.getId());

                logger.info("Successfully uploaded photo {} with ID {}", 
                    file.getOriginalFilename(), photo.getId());
            } catch (Exception ex) {
                // Rollback: Delete file if database save fails
                try {
                    Files.deleteIfExists(fullPath);
                } catch (Exception deleteEx) {
                    logger.error("Error deleting file {} during rollback", fullPath, deleteEx);
                }

                logger.error("Error saving photo metadata to database for {}", file.getOriginalFilename(), ex);
                result.setSuccess(false);
                result.setErrorMessage("Error saving photo information. Please try again.");
            }
        } catch (Exception ex) {
            logger.error("Unexpected error during photo upload for {}", file.getOriginalFilename(), ex);
            result.setSuccess(false);
            result.setErrorMessage("An unexpected error occurred. Please try again.");
        }

        return result;
    }

    /**
     * Delete a photo by ID
     */
    @Override
    public boolean deletePhoto(Long id) {
        try {
            Optional<Photo> photoOpt = photoRepository.findById(id);
            if (!photoOpt.isPresent()) {
                logger.warn("Photo with ID {} not found for deletion", id);
                return false;
            }

            Photo photo = photoOpt.get();

            // Delete file from disk
            Path fullPath = Paths.get(uploadPath, photo.getStoredFileName());
            try {
                Files.deleteIfExists(fullPath);
            } catch (Exception ex) {
                logger.error("Error deleting file {} for photo ID {}", fullPath, id, ex);
                // Continue with database deletion even if file deletion fails
            }

            // Delete from database
            photoRepository.delete(photo);

            logger.info("Successfully deleted photo ID {}", id);
            return true;
        } catch (Exception ex) {
            logger.error("Error deleting photo with ID {}", id, ex);
            throw new RuntimeException("Error deleting photo", ex);
        }
    }

    /**
     * Get the previous photo (older) for navigation
     */
    @Override
    @Transactional(readOnly = true)
    public Optional<Photo> getPreviousPhoto(Photo currentPhoto) {
        List<Photo> olderPhotos = photoRepository.findPhotosUploadedBefore(currentPhoto.getUploadedAt());
        return olderPhotos.isEmpty() ? Optional.<Photo>empty() : Optional.of(olderPhotos.get(0));
    }

    /**
     * Get the next photo (newer) for navigation
     */
    @Override
    @Transactional(readOnly = true)
    public Optional<Photo> getNextPhoto(Photo currentPhoto) {
        List<Photo> newerPhotos = photoRepository.findPhotosUploadedAfter(currentPhoto.getUploadedAt());
        return newerPhotos.isEmpty() ? Optional.<Photo>empty() : Optional.of(newerPhotos.get(0));
    }

    /**
     * Extract file extension from filename
     */
    private String getFileExtension(String filename) {
        if (filename == null || filename.isEmpty()) {
            return "";
        }
        int lastDotIndex = filename.lastIndexOf('.');
        return lastDotIndex > 0 ? filename.substring(lastDotIndex) : "";
    }
}