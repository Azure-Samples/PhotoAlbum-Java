package com.photoalbum.integration;

import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/**
 * Abstract base class for PostgreSQL integration tests using Testcontainers.
 * This class provides a shared PostgreSQL container that simulates the production
 * PostgreSQL database for integration testing purposes.
 *
 * All integration test classes should extend this class to share the same
 * PostgreSQL container configuration.
 */
@Testcontainers
public abstract class AbstractPostgreSQLIntegrationTest {

    /**
     * PostgreSQL container using version 15 (alpine for faster startup).
     * Container is shared across all tests in the same JVM for better performance.
     */
    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15-alpine")
            .withDatabaseName("photoalbum_test")
            .withUsername("testuser")
            .withPassword("testpassword");

    /**
     * Dynamically configure Spring datasource properties to point to the Testcontainer.
     * This overrides application properties to use the containerized PostgreSQL.
     */
    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
        registry.add("spring.datasource.driver-class-name", () -> "org.postgresql.Driver");
        registry.add("spring.jpa.database-platform", () -> "org.hibernate.dialect.PostgreSQLDialect");
        registry.add("spring.jpa.hibernate.ddl-auto", () -> "create-drop");
        registry.add("spring.jpa.show-sql", () -> "true");
    }
}
