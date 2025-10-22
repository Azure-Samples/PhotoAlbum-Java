package com.photoalbum.controller;

import com.photoalbum.model.Photo;
import com.photoalbum.service.PhotoService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;

import java.net.MalformedURLException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Optional;

/**
 * Controller for serving photo files with indirect access
 */
@Controller
@RequestMapping("/photo")
public class PhotoFileController {

    private static final Logger logger = LoggerFactory.getLogger(PhotoFileController.class);

    private final PhotoService photoService;
    private final String uploadPath;

    public PhotoFileController(PhotoService photoService, 
                              @Value("${app.file-upload.upload-path}") String uploadPath) {
        this.photoService = photoService;
        this.uploadPath = uploadPath;
    }

    /**
     * Serves a photo file by ID
     */
    @GetMapping("/{id}")
    public ResponseEntity<Resource> servePhoto(@PathVariable Long id) {
        if (id == null) {
            logger.warn("Photo file request with null ID");
            return ResponseEntity.notFound().build();
        }

        try {
            Optional<Photo> photoOpt = photoService.getPhotoById(id);

            if (!photoOpt.isPresent()) {
                logger.warn("Photo with ID {} not found", id);
                return ResponseEntity.notFound().build();
            }

            Photo photo = photoOpt.get();

            // Construct the physical file path
            Path filePath = Paths.get(uploadPath).resolve(photo.getStoredFileName());
            Resource resource;
            try {
                resource = new UrlResource(filePath.toUri());
            } catch (MalformedURLException e) {
                logger.error("Malformed URL for photo ID {} at path {}", id, filePath, e);
                return ResponseEntity.notFound().build();
            }

            if (!resource.exists() || !resource.isReadable()) {
                logger.error("Physical file not found for photo ID {} at path {}", id, filePath);
                return ResponseEntity.notFound().build();
            }

            try {
                logger.debug("Serving photo ID {} ({}, {} bytes)",
                        id, photo.getOriginalFileName(), resource.contentLength());
            } catch (Exception e) {
                logger.debug("Serving photo ID {} ({})", id, photo.getOriginalFileName());
            }

            // Return the file with appropriate content type and enable caching
            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType(photo.getMimeType()))
                    .header(HttpHeaders.CACHE_CONTROL, "public, max-age=31536000") // Cache for 1 year
                    .header(HttpHeaders.ETAG, String.format("\"%d-%d\"", photo.getId(), 
                            photo.getUploadedAt().atZone(java.time.ZoneOffset.UTC).toEpochSecond()))
                    .body(resource);
        } catch (Exception ex) {
            logger.error("Error serving photo with ID {}", id, ex);
            return ResponseEntity.status(500).build();
        }
    }
}