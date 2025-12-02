package com.photoalbum.model;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Represents an uploaded photo with metadata for display and management
 */
public class Photo {

    private String id;
    private String originalFileName;
    private byte[] photoData;
    private String storedFileName;
    private String filePath;
    private Long fileSize;
    private String mimeType;
    private LocalDateTime uploadedAt;
    private Integer width;
    private Integer height;

    // Default constructor
    public Photo() {
        this.id = UUID.randomUUID().toString();
        this.uploadedAt = LocalDateTime.now();
    }

    // Constructor with required fields
    public Photo(String originalFileName, byte[] photoData, String storedFileName, String filePath, Long fileSize, String mimeType) {
        this();
        this.originalFileName = originalFileName;
        this.photoData = photoData;
        this.storedFileName = storedFileName;
        this.filePath = filePath;
        this.fileSize = fileSize;
        this.mimeType = mimeType;
    }

    // Constructor with required fields (file system compatibility)
    public Photo(String originalFileName, String storedFileName, String filePath, Long fileSize, String mimeType) {
        this();
        this.originalFileName = originalFileName;
        this.storedFileName = storedFileName;
        this.filePath = filePath;
        this.fileSize = fileSize;
        this.mimeType = mimeType;
    }

    // Getters and Setters
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getOriginalFileName() {
        return originalFileName;
    }

    public void setOriginalFileName(String originalFileName) {
        this.originalFileName = originalFileName;
    }

    public byte[] getPhotoData() {
        return photoData;
    }

    public void setPhotoData(byte[] photoData) {
        this.photoData = photoData;
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