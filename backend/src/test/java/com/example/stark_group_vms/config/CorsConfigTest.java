package com.example.stark_group_vms.config;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.example.stark_group_vms.controller.VehicleController;
import com.example.stark_group_vms.service.VehicleService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

/** CORS with the local defaults from application.properties (no env vars set). */
@WebMvcTest(VehicleController.class)
@Import({SecurityConfig.class, CorsConfig.class})
class CorsConfigTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private VehicleService vehicleService;

    @Test
    void localhostOnAnyPortIsAllowed() throws Exception {
        for (String origin : new String[] {"http://localhost:8686", "http://localhost:53771", "http://127.0.0.1:9000"}) {
            mockMvc.perform(options("/api/vehicles")
                            .header("Origin", origin)
                            .header("Access-Control-Request-Method", "GET"))
                    .andExpect(status().isOk())
                    .andExpect(header().string("Access-Control-Allow-Origin", origin));
        }
    }

    @Test
    void foreignOriginPreflightIsRefused() throws Exception {
        mockMvc.perform(options("/api/vehicles")
                        .header("Origin", "https://evil.example")
                        .header("Access-Control-Request-Method", "DELETE"))
                .andExpect(status().isForbidden())
                .andExpect(header().doesNotExist("Access-Control-Allow-Origin"));
    }

    @Test
    void foreignOriginRequestIsRefused() throws Exception {
        mockMvc.perform(get("/api/vehicles").header("Origin", "https://evil.example"))
                .andExpect(status().isForbidden())
                .andExpect(header().doesNotExist("Access-Control-Allow-Origin"));
    }
}
