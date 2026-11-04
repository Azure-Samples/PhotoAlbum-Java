package com.photoalbum;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class PhotoAlbumApplicationTests {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void contextLoads() {
        // This test ensures that the Spring context loads correctly
    }

    @Test
    void uploadRequiresAuthentication() throws Exception {
        mockMvc.perform(post("/upload"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void photoDeletionRequiresAuthentication() throws Exception {
        mockMvc.perform(post("/detail/test-id/delete"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void unconfiguredReadOnlyRouteRemainsPublic() throws Exception {
        mockMvc.perform(get("/security-public-access-check"))
                .andExpect(status().isNotFound());
    }
}