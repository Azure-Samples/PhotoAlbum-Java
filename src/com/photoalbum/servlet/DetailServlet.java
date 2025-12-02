package com.photoalbum.servlet;

import com.photoalbum.dao.PhotoDAO;
import com.photoalbum.model.Photo;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

/**
 * Detail Servlet - Displays photo details and handles deletion
 * Replaces DetailController from Spring Boot version
 */
public class DetailServlet extends HttpServlet {

    private PhotoDAO photoDAO;

    @Override
    public void init() throws ServletException {
        super.init();
        photoDAO = new PhotoDAO();
    }

    /**
     * GET - Display photo details page
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String photoId = request.getParameter("id");

        if (photoId == null || photoId.isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/");
            return;
        }

        try {
            // Find photo by ID
            Photo photo = photoDAO.findById(photoId);

            if (photo == null) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Photo not found");
                return;
            }

            // Set photo as request attribute
            request.setAttribute("photo", photo);

            // Forward to detail.jsp
            request.getRequestDispatcher("/WEB-INF/jsp/detail.jsp").forward(request, response);

        } catch (SQLException e) {
            log("Error loading photo details", e);
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * POST - Handle photo deletion
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");
        String photoId = request.getParameter("id");

        if ("delete".equals(action) && photoId != null && !photoId.isEmpty()) {
            try {
                // Delete photo from database
                boolean deleted = photoDAO.deleteById(photoId);

                if (deleted) {
                    // Redirect to home with success message
                    response.sendRedirect(request.getContextPath() + "/?success=deleted");
                } else {
                    // Photo not found
                    response.sendRedirect(request.getContextPath() + "/?error=notfound");
                }

            } catch (SQLException e) {
                log("Error deleting photo", e);
                response.sendRedirect(request.getContextPath() + "/?error=database");
            }
        } else {
            // Invalid request
            response.sendRedirect(request.getContextPath() + "/");
        }
    }
}
