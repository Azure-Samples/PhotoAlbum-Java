package com.photoalbum.model;

/**
 * Result object for photo upload operations
 */
public class UploadResult {
    private boolean success;
    private String fileName;
    private String errorMessage;
    private Long photoId;

    // Default constructor
    public UploadResult() {
    }

    // Constructor for successful upload
    public UploadResult(boolean success, String fileName, Long photoId) {
        this.success = success;
        this.fileName = fileName;
        this.photoId = photoId;
    }

    // Constructor for failed upload
    public UploadResult(boolean success, String fileName, String errorMessage) {
        this.success = success;
        this.fileName = fileName;
        this.errorMessage = errorMessage;
    }

    // Getters and Setters
    public boolean isSuccess() {
        return success;
    }

    public void setSuccess(boolean success) {
        this.success = success;
    }

    public String getFileName() {
        return fileName;
    }

    public void setFileName(String fileName) {
        this.fileName = fileName;
    }

    public String getErrorMessage() {
        return errorMessage;
    }

    public void setErrorMessage(String errorMessage) {
        this.errorMessage = errorMessage;
    }

    public Long getPhotoId() {
        return photoId;
    }

    public void setPhotoId(Long photoId) {
        this.photoId = photoId;
    }

    @Override
    public String toString() {
        return "UploadResult{" +
                "success=" + success +
                ", fileName='" + fileName + '\'' +
                ", errorMessage='" + errorMessage + '\'' +
                ", photoId=" + photoId +
                '}';
    }
}