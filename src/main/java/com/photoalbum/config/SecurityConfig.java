package com.photoalbum.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.web.SecurityFilterChain;

/**
 * Security configuration.
 *
 * The photo gallery is publicly readable, but the state-changing endpoints
 * (photo upload and delete) require authentication so anonymous callers can no
 * longer create or destroy data (CWE-862 / CWE-306). The admin credentials are
 * supplied via environment variables (app.admin.username / app.admin.password),
 * never hard-coded.
 */
@Configuration
public class SecurityConfig {

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public InMemoryUserDetailsManager userDetailsService(
            PasswordEncoder passwordEncoder,
            @Value("${app.admin.username:admin}") String adminUsername,
            @Value("${app.admin.password}") String adminPassword) {
        UserDetails admin = User.withUsername(adminUsername)
                .password(passwordEncoder.encode(adminPassword))
                .roles("ADMIN")
                .build();
        return new InMemoryUserDetailsManager(admin);
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            // Stateless HTTP Basic auth: credentials are sent per request, so a
            // session-based CSRF token is not applicable. CSRF is disabled to
            // keep this security fix minimal without breaking the JSON upload API.
            .csrf().disable()
            .sessionManagement().sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            .and()
            .authorizeRequests()
                // Default deny for state-changing operations (CWE-862 / CWE-306).
                .antMatchers(HttpMethod.POST, "/upload", "/detail/*/delete").authenticated()
                // Public, read-only photo gallery.
                .anyRequest().permitAll()
            .and()
            .httpBasic();
        return http.build();
    }
}
