package com.photoalbum.util;

import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

/**
 * Database configuration and connection management
 * Reads database properties from application.properties
 */
public class DatabaseConfig {

    private static String url;
    private static String username;
    private static String password;
    private static String driverClassName;

    static {
        loadProperties();
        initializeDatabase();
    }

    /**
     * Load database properties from application.properties
     */
    private static void loadProperties() {
        Properties props = new Properties();

        try (InputStream input = DatabaseConfig.class.getClassLoader()
                .getResourceAsStream("application.properties")) {

            if (input == null) {
                System.err.println("Unable to find application.properties");
                return;
            }

            props.load(input);

            // Read properties
            url = props.getProperty("app.datasource.url");
            username = props.getProperty("app.datasource.username");
            password = props.getProperty("app.datasource.password");
            driverClassName = props.getProperty("app.datasource.driver-class-name");

            // Load JDBC driver
            if (driverClassName != null && !driverClassName.isEmpty()) {
                try {
                    Class.forName(driverClassName);
                    System.out.println("JDBC Driver loaded: " + driverClassName);
                } catch (ClassNotFoundException e) {
                    System.err.println("JDBC Driver not found: " + driverClassName);
                    e.printStackTrace();
                }
            }

        } catch (IOException e) {
            System.err.println("Error loading application.properties");
            e.printStackTrace();
        }
    }

    /**
     * Get a database connection
     */
    public static Connection getConnection() throws SQLException {
        if (url == null || username == null || password == null) {
            throw new SQLException("Database configuration not loaded properly");
        }

        return DriverManager.getConnection(url, username, password);
    }

    /**
     * Test database connection
     */
    public static boolean testConnection() {
        try (Connection conn = getConnection()) {
            return conn != null && !conn.isClosed();
        } catch (SQLException e) {
            System.err.println("Database connection test failed: " + e.getMessage());
            return false;
        }
    }

    // Getters
    public static String getUrl() {
        return url;
    }

    public static String getUsername() {
        return username;
    }

    public static String getDriverClassName() {
        return driverClassName;
    }

    /**
     * Initialize database schema for H2 (auto-create tables)
     */
    private static void initializeDatabase() {
        // Only initialize if using H2
        if (url != null && url.contains("jdbc:h2")) {
            try (Connection conn = getConnection()) {
                String createTableSQL =
                    "CREATE TABLE IF NOT EXISTS photos (" +
                    "    id VARCHAR(36) PRIMARY KEY," +
                    "    original_file_name VARCHAR(255) NOT NULL," +
                    "    photo_data BLOB," +
                    "    stored_file_name VARCHAR(255) NOT NULL," +
                    "    file_path VARCHAR(500)," +
                    "    file_size BIGINT NOT NULL," +
                    "    mime_type VARCHAR(50) NOT NULL," +
                    "    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL," +
                    "    width INT," +
                    "    height INT" +
                    ")";

                conn.createStatement().execute(createTableSQL);

                String createIndexSQL = "CREATE INDEX IF NOT EXISTS idx_photos_uploaded_at ON photos(uploaded_at)";
                conn.createStatement().execute(createIndexSQL);

                System.out.println("H2 database initialized successfully");
            } catch (SQLException e) {
                System.err.println("Failed to initialize H2 database: " + e.getMessage());
                e.printStackTrace();
            }
        }
    }
}
