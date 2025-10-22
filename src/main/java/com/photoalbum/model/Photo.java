package com.photoalbum.model;

import javax.persistence.*;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Positive;
import javax.validation.constraints.Size;

import java.time.LocalDateTime;

/**
 * Represents an uploaded photo with metadata for display and management
 */
@Entity
@Table(name = "photos", indexes = {
    @Index(name = "idx_photos_uploaded_at", columnList = "uploaded_at", unique = false)
})
public class Photo {

    /**
     * Unique identifier for the photo
     */
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "photo_seq")
    @SequenceGenerator(name = "photo_seq", sequenceName = "PHOTO_SEQ", allocationSize = 1)
    private Long id;

    /**
     * Original filename as uploaded by user
     */
    @NotBlank
    @Size(max = 255)
    @Column(name = "original_file_name", nullable = false, length = 255)
    private String originalFileName;

    /**
     * GUID-based filename with extension stored on disk
     */
    @NotBlank
    @Size(max = 255)
    @Column(name = "stored_file_name", nullable = false, length = 255)
    private String storedFileName;

    /**
     * Relative path from static resources (e.g., /uploads/abc123.jpg)
     */
    @NotBlank
    @Size(max = 500)
    @Column(name = "file_path", nullable = false, length = 500)
    private String filePath;

    /**
     * File size in bytes
     */
    @NotNull
    @Positive
    @Column(name = "file_size", nullable = false)
    private Long fileSize;

    /**
     * MIME type (e.g., image/jpeg, image/png)
     */
    @NotBlank
    @Size(max = 50)
    @Column(name = "mime_type", nullable = false, length = 50)
    private String mimeType;

    /**
     * Timestamp of upload
     */
    @NotNull
    @Column(name = "uploaded_at", nullable = false)
    private LocalDateTime uploadedAt;

    /**
     * Image width in pixels (populated after upload)
     */
    @Column(name = "width")
    private Integer width;

    /**
     * Image height in pixels (populated after upload)
     */
    @Column(name = "height")
    private Integer height;

    // Default constructor
    public Photo() {
        this.uploadedAt = LocalDateTime.now();
    }

    // Constructor with required fields
    public Photo(String originalFileName, String storedFileName, String filePath, Long fileSize, String mimeType) {
        this();
        this.originalFileName = originalFileName;
        this.storedFileName = storedFileName;
        this.filePath = filePath;
        this.fileSize = fileSize;
        this.mimeType = mimeType;
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getOriginalFileName() {
        return originalFileName;
    }

    public void setOriginalFileName(String originalFileName) {
        this.originalFileName = originalFileName;
    }

    public String getStoredFileName() {
        return storedFileName;
    }

    public void setStoredFileName(String storedFileName) {
        this.storedFileName = storedFileName;
    }

    public String getFilePath() {
        return filePath;
    }

    public void setFilePath(String filePath) {
        this.filePath = filePath;
    }

    public Long getFileSize() {
        return fileSize;
    }

    public void setFileSize(Long fileSize) {
        this.fileSize = fileSize;
    }

    public String getMimeType() {
        return mimeType;
    }

    public void setMimeType(String mimeType) {
        this.mimeType = mimeType;
    }

    public LocalDateTime getUploadedAt() {
        return uploadedAt;
    }

    public void setUploadedAt(LocalDateTime uploadedAt) {
        this.uploadedAt = uploadedAt;
    }

    public Integer getWidth() {
        return width;
    }

    public void setWidth(Integer width) {
        this.width = width;
    }

    public Integer getHeight() {
        return height;
    }

    public void setHeight(Integer height) {
        this.height = height;
    }

    @Override
    public String toString() {
        return "Photo{" +
                "id=" + id +
                ", originalFileName='" + originalFileName + '\'' +
                ", storedFileName='" + storedFileName + '\'' +
                ", filePath='" + filePath + '\'' +
                ", fileSize=" + fileSize +
                ", mimeType='" + mimeType + '\'' +
                ", uploadedAt=" + uploadedAt +
                ", width=" + width +
                ", height=" + height +
                '}';
    }
}