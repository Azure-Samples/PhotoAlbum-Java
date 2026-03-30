package com.photoalbum.servlet;

import com.photoalbum.dao.PhotoDAO;
import com.photoalbum.model.Photo;

import jakarta.servlet.ServletException;
import jakarta.servlet.ServletOutputStream;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

/**
 * Download Servlet - Serves photo files as downloads or inline display
 * Replaces PhotoFileController from Spring Boot version
 */
public class DownloadServlet extends HttpServlet {

    private PhotoDAO photoDAO;

    @Override
    public void init() throws ServletException {
        super.init();
        photoDAO = new PhotoDAO();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String photoId = request.getParameter("id");
        String mode = request.getParameter("mode"); // "download" or "inline"

        if (photoId == null || photoId.isEmpty()) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Photo ID is required");
            return;
        }

        try {
            // Find photo by ID
            Photo photo = photoDAO.findById(photoId);

            if (photo == null) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Photo not found");
                return;
            }

            // Get photo data
            byte[] photoData = photo.getPhotoData();

            if (photoData == null || photoData.length == 0) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Photo data not found");
                return;
            }

            // Set response headers
            response.setContentType(photo.getMimeType());
            response.setContentLength(photoData.length);

            // Set Content-Disposition header
            if ("download".equals(mode)) {
                // Force download
                response.setHeader("Content-Disposition",
                    "attachment; filename=\"" + photo.getOriginalFileName() + "\"");
            } else {
                // Display inline (default)
                response.setHeader("Content-Disposition",
                    "inline; filename=\"" + photo.getOriginalFileName() + "\"");
            }

            // Set caching headers
            response.setHeader("Cache-Control", "public, max-age=31536000");
            response.setDateHeader("Expires", System.currentTimeMillis() + 31536000000L);

            // Write photo data to response
            try (ServletOutputStream out = response.getOutputStream()) {
                out.write(photoData);
                out.flush();
            }

        } catch (SQLException e) {
            log("Error serving photo file", e);
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    }
}
