package com.photoalbum.config;

import com.azure.security.keyvault.secrets.SecretClient;
import com.azure.security.keyvault.secrets.models.KeyVaultSecret;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.jdbc.DataSourceBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

import javax.sql.DataSource;

@Configuration
public class DataSourceConfig {

    @Autowired(required = false)
    private SecretClient secretClient;

    @Bean
    @Primary
    public DataSource dataSource() {
        DataSourceBuilder<?> dataSourceBuilder = DataSourceBuilder.create();
        
        if (secretClient != null) {
            // Retrieve database credentials from Azure Key Vault
            try {
                KeyVaultSecret usernameSecret = secretClient.getSecret("db-username");
                KeyVaultSecret passwordSecret = secretClient.getSecret("db-password");
                KeyVaultSecret urlSecret = secretClient.getSecret("db-url");
                
                dataSourceBuilder.username(usernameSecret.getValue());
                dataSourceBuilder.password(passwordSecret.getValue());
                dataSourceBuilder.url(urlSecret.getValue());
            } catch (Exception e) {
                // Fallback to properties if Key Vault is not available
                System.err.println("Failed to retrieve secrets from Azure Key Vault: " + e.getMessage());
                System.err.println("Falling back to application.properties configuration");
                // Spring Boot will use the default configuration from application.properties
                return null;
            }
        }
        
        dataSourceBuilder.driverClassName("oracle.jdbc.OracleDriver");
        return dataSourceBuilder.build();
    }
}
