package com.photoalbum.servlet;

import com.photoalbum.dao.PhotoDAO;
import com.photoalbum.model.Photo;

import javax.imageio.ImageIO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.sql.SQLException;
import java.util.UUID;

/**
 * Upload Servlet - Handles photo uploads
 * Replaces upload functionality from HomeController
 */
@MultipartConfig(
    maxFileSize = 10485760,      // 10MB
    maxRequestSize = 10485760,    // 10MB
    fileSizeThreshold = 0
)
public class UploadServlet extends HttpServlet {

    private PhotoDAO photoDAO;

    @Override
    public void init() throws ServletException {
        super.init();
        photoDAO = new PhotoDAO();
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {
            // Get uploaded file part
            Part filePart = request.getPart("file");

            if (filePart == null || filePart.getSize() == 0) {
                response.sendRedirect(request.getContextPath() + "/?error=nofile");
                return;
            }

            // Get file info
            String originalFileName = getFileName(filePart);
            String contentType = filePart.getContentType();
            long fileSize = filePart.getSize();

            // Validate file type
            if (!isValidImageType(contentType)) {
                response.sendRedirect(request.getContextPath() + "/?error=invalidtype");
                return;
            }

            // Read file data
            byte[] photoData = readAllBytes(filePart.getInputStream());

            // Generate stored filename
            String storedFileName = UUID.randomUUID().toString() + getFileExtension(originalFileName);
            String filePath = "/uploads/" + storedFileName;

            // Create Photo object
            Photo photo = new Photo();
            photo.setOriginalFileName(originalFileName);
            photo.setPhotoData(photoData);
            photo.setStoredFileName(storedFileName);
            photo.setFilePath(filePath);
            photo.setFileSize(fileSize);
            photo.setMimeType(contentType);

            // Get image dimensions
            try {
                BufferedImage image = ImageIO.read(new ByteArrayInputStream(photoData));
                if (image != null) {
                    photo.setWidth(image.getWidth());
                    photo.setHeight(image.getHeight());
                }
            } catch (Exception e) {
                log("Could not read image dimensions", e);
            }

            // Save to database
            photoDAO.save(photo);

            // Redirect to home page with success message
            response.sendRedirect(request.getContextPath() + "/?success=uploaded");

        } catch (SQLException e) {
            log("Error uploading photo", e);
            response.sendRedirect(request.getContextPath() + "/?error=database");
        }
    }

    /**
     * Extract filename from Part header
     */
    private String getFileName(Part part) {
        String contentDisposition = part.getHeader("content-disposition");

        for (String token : contentDisposition.split(";")) {
            if (token.trim().startsWith("filename")) {
                return token.substring(token.indexOf('=') + 1).trim()
                        .replace("\"", "");
            }
        }

        return "unknown";
    }

    /**
     * Get file extension from filename
     */
    private String getFileExtension(String filename) {
        int lastDot = filename.lastIndexOf('.');
        if (lastDot > 0) {
            return filename.substring(lastDot);
        }
        return "";
    }

    /**
     * Validate image MIME type
     */
    private boolean isValidImageType(String mimeType) {
        return mimeType != null && (
            mimeType.equals("image/jpeg") ||
            mimeType.equals("image/jpg") ||
            mimeType.equals("image/png") ||
            mimeType.equals("image/gif") ||
            mimeType.equals("image/webp")
        );
    }

    /**
     * Read all bytes from InputStream (Java 8 compatible)
     */
    private byte[] readAllBytes(InputStream inputStream) throws IOException {
        byte[] buffer = new byte[8192];
        int bytesRead;
        java.io.ByteArrayOutputStream output = new java.io.ByteArrayOutputStream();

        while ((bytesRead = inputStream.read(buffer)) != -1) {
            output.write(buffer, 0, bytesRead);
        }

        return output.toByteArray();
    }
}
