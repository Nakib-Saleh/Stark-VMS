package com.example.stark_group_vms.controller;

import com.example.stark_group_vms.dto.VehicleResponse;
import com.example.stark_group_vms.dto.VehicleRequest;
import com.example.stark_group_vms.enums.FuelType;
import com.example.stark_group_vms.enums.VehicleStatus;
import com.example.stark_group_vms.enums.VehicleType;
import com.example.stark_group_vms.exception.DuplicateResourceException;
import com.example.stark_group_vms.exception.GlobalExceptionHandler;
import com.example.stark_group_vms.exception.InvalidRequestException;
import java.sql.SQLException;
import org.springframework.dao.DataIntegrityViolationException;
import com.example.stark_group_vms.exception.ResourceNotFoundException;
import com.example.stark_group_vms.service.VehicleService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.time.LocalDateTime;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class VehicleControllerTest {

    private MockMvc mockMvc;
    private VehicleService vehicleService;

    @BeforeEach
    void setUp() {
        vehicleService = mock(VehicleService.class);
        VehicleController controller = new VehicleController(vehicleService);
        mockMvc = MockMvcBuilders.standaloneSetup(controller)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    private VehicleResponse sampleVehicleResponse() {
        return new VehicleResponse(
                1L,
                "DHA-METRO-GA-12-3456",
                VehicleType.CAR,
                "Stark Logistics",
                "Toyota",
                "Corolla",
                2023,
                "Silver",
                FuelType.HYBRID,
                5,
                "Rahim Uddin",
                "+8801711000000",
                VehicleStatus.AVAILABLE,
                LocalDateTime.now(),
                LocalDateTime.now()
        );
    }

    @Test
    void getVehicles_returnsPagedResponseJson() throws Exception {
        VehicleResponse v = sampleVehicleResponse();
        // Page 1 of size 1 out of 3 vehicles: a middle page, so last and hasNext are both meaningful.
        Page<VehicleResponse> page = new PageImpl<>(List.of(v), PageRequest.of(1, 1), 3);
        when(vehicleService.getVehicles(1, 1, null, null)).thenReturn(page);

        mockMvc.perform(get("/api/vehicles")
                        .param("page", "1")
                        .param("size", "1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content[0].id").value(1))
                .andExpect(jsonPath("$.content[0].vehicleNumber").value("DHA-METRO-GA-12-3456"))
                .andExpect(jsonPath("$.number").value(1))
                .andExpect(jsonPath("$.size").value(1))
                .andExpect(jsonPath("$.totalElements").value(3))
                .andExpect(jsonPath("$.totalPages").value(3))
                .andExpect(jsonPath("$.last").value(false))
                .andExpect(jsonPath("$.hasNext").value(true));
    }

    @Test
    void getVehicleById_returnsVehicle() throws Exception {
        when(vehicleService.getVehicleById(1L)).thenReturn(sampleVehicleResponse());

        mockMvc.perform(get("/api/vehicles/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(1))
                .andExpect(jsonPath("$.vehicleNumber").value("DHA-METRO-GA-12-3456"));
    }

    @Test
    void getVehicleById_notFound_returns404() throws Exception {
        when(vehicleService.getVehicleById(99L))
                .thenThrow(new ResourceNotFoundException("Vehicle not found with id: 99"));

        mockMvc.perform(get("/api/vehicles/99"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("Vehicle not found with id: 99"));
    }

    @Test
    void createVehicle_valid_returns201() throws Exception {
        when(vehicleService.createVehicle(any(VehicleRequest.class))).thenReturn(sampleVehicleResponse());

        String payload = """
                {
                  "vehicleNumber": "DHA-METRO-GA-12-3456",
                  "vehicleType": "CAR",
                  "brand": "Toyota",
                  "model": "Corolla",
                  "manufacturingYear": 2023,
                  "color": "Silver",
                  "fuelType": "HYBRID",
                  "seatingCapacity": 5,
                  "driverName": "Rahim Uddin",
                  "driverPhone": "+8801711000000",
                  "status": "AVAILABLE"
                }
                """;

        mockMvc.perform(post("/api/vehicles")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(1))
                .andExpect(jsonPath("$.vehicleNumber").value("DHA-METRO-GA-12-3456"));
    }

    @Test
    void createVehicle_duplicateNumber_returns409() throws Exception {
        when(vehicleService.createVehicle(any(VehicleRequest.class)))
                .thenThrow(new DuplicateResourceException("Vehicle with number 'DHA-METRO-GA-12-3456' already exists"));

        String payload = """
                {
                  "vehicleNumber": "DHA-METRO-GA-12-3456",
                  "vehicleType": "CAR",
                  "brand": "Toyota",
                  "model": "Corolla",
                  "fuelType": "HYBRID"
                }
                """;

        mockMvc.perform(post("/api/vehicles")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.status").value(409))
                .andExpect(jsonPath("$.message").value("Vehicle with number 'DHA-METRO-GA-12-3456' already exists"));
    }

    @Test
    void createVehicle_validationError_returns400() throws Exception {
        String invalidPayload = """
                {
                  "vehicleNumber": "",
                  "brand": "",
                  "model": ""
                }
                """;

        mockMvc.perform(post("/api/vehicles")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(invalidPayload))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.message").isNotEmpty())
                .andExpect(jsonPath("$.errors.vehicleNumber").value("Vehicle number is required"))
                .andExpect(jsonPath("$.errors.vehicleType").value("Vehicle type is required"));
    }

    @Test
    void updateVehicle_valid_returns200() throws Exception {
        VehicleResponse updated = new VehicleResponse(
                1L,
                "DHA-METRO-GA-12-3456",
                VehicleType.CAR,
                "Stark Logistics",
                "Toyota",
                "Corolla",
                2023,
                "Black",
                FuelType.HYBRID,
                5,
                "Rahim Uddin",
                "+8801711000000",
                VehicleStatus.AVAILABLE,
                LocalDateTime.now(),
                LocalDateTime.now()
        );
        when(vehicleService.updateVehicle(eq(1L), any(VehicleRequest.class))).thenReturn(updated);

        String payload = """
                {
                  "vehicleNumber": "DHA-METRO-GA-12-3456",
                  "vehicleType": "CAR",
                  "brand": "Toyota",
                  "model": "Corolla",
                  "fuelType": "HYBRID",
                  "color": "Black"
                }
                """;

        mockMvc.perform(put("/api/vehicles/1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.color").value("Black"));
    }

    @Test
    void deleteVehicle_returns204() throws Exception {
        doNothing().when(vehicleService).deleteVehicle(1L);

        mockMvc.perform(delete("/api/vehicles/1"))
                .andExpect(status().isNoContent());
    }

    @Test
    void createVehicle_databaseRejectsDuplicate_returns409WithFieldError() throws Exception {
        // Two saves raced past the service check; the database's unique index refused the second
        // (message as PostgreSQL words it; VehicleApiIntegrationTest checks the real one).
        when(vehicleService.createVehicle(any(VehicleRequest.class))).thenThrow(new DataIntegrityViolationException(
                "could not execute statement",
                new SQLException("ERROR: duplicate key value violates unique constraint \"uk_vehicles_vehicle_number\"")));

        mockMvc.perform(post("/api/vehicles")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"vehicleNumber": "DHA-METRO-GA-12-3456", "vehicleType": "CAR",
                                 "brand": "Toyota", "model": "Corolla", "fuelType": "HYBRID"}
                                """))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.errors.vehicleNumber").value("This vehicle number is already registered"));
    }

    @Test
    void getVehicles_sizeOverCap_returns400WithReason() throws Exception {
        when(vehicleService.getVehicles(0, 101, null, null))
                .thenThrow(new InvalidRequestException("Page size must be between 1 and 100"));

        mockMvc.perform(get("/api/vehicles").param("size", "101"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Page size must be between 1 and 100"));
    }
}
