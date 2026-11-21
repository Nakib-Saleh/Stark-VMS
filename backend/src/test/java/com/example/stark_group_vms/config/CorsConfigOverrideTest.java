package com.example.stark_group_vms.config;

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

/** CORS as on the deployed API: the configured value replaces the localhost default. */
@WebMvcTest(controllers = VehicleController.class,
        properties = "app.cors.allowed-origins=https://stark-vms.netlify.app")
@Import({SecurityConfig.class, CorsConfig.class})
class CorsConfigOverrideTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private VehicleService vehicleService;

    @Test
    void configuredOriginIsAllowed() throws Exception {
        mockMvc.perform(options("/api/vehicles")
                        .header("Origin", "https://stark-vms.netlify.app")
                        .header("Access-Control-Request-Method", "POST"))
                .andExpect(status().isOk())
                .andExpect(header().string("Access-Control-Allow-Origin", "https://stark-vms.netlify.app"));
    }

    @Test
    void localhostIsRefusedOnceAnOriginIsConfigured() throws Exception {
        mockMvc.perform(options("/api/vehicles")
                        .header("Origin", "http://localhost:8686")
                        .header("Access-Control-Request-Method", "GET"))
                .andExpect(status().isForbidden())
                .andExpect(header().doesNotExist("Access-Control-Allow-Origin"));
    }
}
