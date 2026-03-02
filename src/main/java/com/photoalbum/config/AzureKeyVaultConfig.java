package com.photoalbum.config;

import com.azure.identity.DefaultAzureCredentialBuilder;
import com.azure.security.keyvault.secrets.SecretClient;
import com.azure.security.keyvault.secrets.SecretClientBuilder;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class AzureKeyVaultConfig {

    @Value("${azure.keyvault.url:}")
    private String keyVaultUrl;

    @Bean
    public SecretClient secretClient() {
        if (keyVaultUrl == null || keyVaultUrl.isEmpty()) {
            throw new IllegalStateException("Azure Key Vault URL is not configured. Please set azure.keyvault.url property.");
        }
        
        return new SecretClientBuilder()
                .vaultUrl(keyVaultUrl)
                .credential(new DefaultAzureCredentialBuilder().build())
                .buildClient();
    }
}
