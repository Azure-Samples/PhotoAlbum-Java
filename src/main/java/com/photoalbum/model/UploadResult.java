package com.photoalbum.model;

/**
 * Result object for photo upload operations
 */
public class UploadResult {
    private boolean success;
    private String fileName;
    private String errorMessage;
    private String photoId;

    // Default constructor
    public UploadResult() {
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

    public String getPhotoId() {
        return photoId;
    }

    public void setPhotoId(String photoId) {
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