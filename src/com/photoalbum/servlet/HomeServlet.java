package com.photoalbum.servlet;

import com.photoalbum.dao.PhotoDAO;
import com.photoalbum.model.Photo;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

/**
 * Home Servlet - Displays the photo gallery
 * Replaces HomeController from Spring Boot version
 */
public class HomeServlet extends HttpServlet {

    private PhotoDAO photoDAO;

    @Override
    public void init() throws ServletException {
        super.init();
        photoDAO = new PhotoDAO();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {
            // Get all photos from database
            List<Photo> photos = photoDAO.findAll();

            // Set photos as request attribute for JSP
            request.setAttribute("photos", photos);

            // Forward to index.jsp
            request.getRequestDispatcher("/WEB-INF/jsp/index.jsp").forward(request, response);

        } catch (SQLException e) {
            // Log error and show error page
            log("Error loading photos", e);
            request.setAttribute("errorMessage", "Unable to load photos: " + e.getMessage());
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    }
}
