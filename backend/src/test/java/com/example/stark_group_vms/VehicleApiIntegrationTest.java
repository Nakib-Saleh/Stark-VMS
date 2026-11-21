package com.example.stark_group_vms;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.hamcrest.Matchers.not;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.example.stark_group_vms.entity.Vehicle;
import com.example.stark_group_vms.enums.FuelType;
import com.example.stark_group_vms.enums.VehicleStatus;
import com.example.stark_group_vms.enums.VehicleType;
import com.example.stark_group_vms.repository.VehicleRepository;
import java.time.Year;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

/**
 * Runs against the real MySQL (local Docker or the CI service), so it proves what the
 * database itself enforces, not only the service code. Test vehicles use the TEST-IT- prefix
 * and are removed after each test.
 */
@SpringBootTest(properties = "app.admin.seed=false")
@WithMockUser
@AutoConfigureMockMvc
class VehicleApiIntegrationTest {

    private static final String NUMBER = "TEST-IT-GA-11-0001";

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private VehicleRepository repository;

    @AfterEach
    void cleanUp() {
        repository.findAll().stream()
                .filter(v -> v.getVehicleNumber().toUpperCase().startsWith("TEST-IT-"))
                .forEach(repository::delete);
    }

    private static String body(String number, String extra) {
        return """
                {"vehicleNumber": "%s", "vehicleType": "CAR", "brand": "Toyota", "model": "Axio",
                 "fuelType": "HYBRID", "company": "Stark Logistics"%s}
                """.formatted(number, extra);
    }

    @Test
    void numberIsStoredTrimmedAndUpperCase() throws Exception {
        mockMvc.perform(post("/api/vehicles").contentType(MediaType.APPLICATION_JSON)
                        .content(body("  test-it-ga-11-0001 ", "")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.vehicleNumber").value(NUMBER))
                .andExpect(jsonPath("$.company").value("Stark Logistics"));
    }

    @Test
    void sameNumberInDifferentCaseIsRejectedWith409() throws Exception {
        mockMvc.perform(post("/api/vehicles").contentType(MediaType.APPLICATION_JSON).content(body(NUMBER, "")))
                .andExpect(status().isCreated());

        mockMvc.perform(post("/api/vehicles").contentType(MediaType.APPLICATION_JSON)
                        .content(body("Test-It-Ga-11-0001", "")))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.errors.vehicleNumber").value(NUMBER + " is already registered"));
    }

    @Test
    void databaseRejectsCaseVariantDuplicateEvenWithoutTheServiceCheck() {
        Vehicle first = vehicle(NUMBER);
        repository.saveAndFlush(first);

        Vehicle lowerCaseCopy = vehicle(NUMBER.toLowerCase());
        assertThatThrownBy(() -> repository.saveAndFlush(lowerCaseCopy))
                .isInstanceOf(DataIntegrityViolationException.class);
        assertThat(repository.existsByVehicleNumberIgnoreCase(NUMBER)).isTrue();
    }

    @Test
    void clientCannotSetServerOwnedFields() throws Exception {
        mockMvc.perform(post("/api/vehicles").contentType(MediaType.APPLICATION_JSON)
                        .content(body(NUMBER, ", \"id\": 999999, \"createdAt\": \"2000-01-01T00:00:00\"")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(not(999999)))
                .andExpect(jsonPath("$.createdAt").value(not("2000-01-01T00:00:00")));
    }

    @Test
    void invalidFieldsEachGetAPlainMessage() throws Exception {
        String tooLong = "x".repeat(300);
        mockMvc.perform(post("/api/vehicles").contentType(MediaType.APPLICATION_JSON).content("""
                        {"vehicleNumber": "TEST-IT-GA-11-0002", "vehicleType": "CAR", "model": "%s",
                         "fuelType": "HYBRID", "manufacturingYear": 1800, "seatingCapacity": 0}
                        """.formatted(tooLong)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errors.brand").value("Brand is required"))
                .andExpect(jsonPath("$.errors.model").value("Model must be 100 characters or fewer"))
                .andExpect(jsonPath("$.errors.manufacturingYear").value("Manufacturing year must be 1900 or later"))
                .andExpect(jsonPath("$.errors.seatingCapacity").value("Seating capacity must be at least 1"));
    }

    @Test
    void manufacturingYearAfterNextYearIsRejected() throws Exception {
        int tooLate = Year.now().getValue() + 2;
        mockMvc.perform(post("/api/vehicles").contentType(MediaType.APPLICATION_JSON)
                        .content(body(NUMBER, ", \"manufacturingYear\": " + tooLate)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errors.manufacturingYear").exists());
    }

    @Test
    void pageSizeIsCappedAt100() throws Exception {
        mockMvc.perform(get("/api/vehicles").param("size", "100")).andExpect(status().isOk());
        mockMvc.perform(get("/api/vehicles").param("size", "101"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Page size must be between 1 and 100"));
        mockMvc.perform(get("/api/vehicles").param("page", "-1"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Page number can't be negative"));
    }

    @Test
    void pageResponseHasAllSevenFieldsInOrderAndTheyAgreeWithTheDatabase() throws Exception {
        long total = repository.count();
        int size = 3;
        int pages = (int) Math.ceil(total / (double) size);

        String json = mockMvc.perform(get("/api/vehicles").param("page", "0").param("size", String.valueOf(size)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.number").value(0))
                .andExpect(jsonPath("$.size").value(size))
                .andExpect(jsonPath("$.totalElements").value(total))
                .andExpect(jsonPath("$.totalPages").value(pages))
                .andExpect(jsonPath("$.last").value(pages <= 1))
                .andExpect(jsonPath("$.hasNext").value(pages > 1))
                .andReturn().getResponse().getContentAsString();

        // Top-level keys, in order (the content array's own keys come after "content" and are skipped).
        String top = json.substring(json.lastIndexOf(']'));
        assertThat(json).startsWith("{\"content\":[");
        assertThat(top).containsSubsequence("\"number\"", "\"size\"", "\"totalElements\"",
                "\"totalPages\"", "\"last\"", "\"hasNext\"");

        mockMvc.perform(get("/api/vehicles").param("page", String.valueOf(Math.max(pages - 1, 0)))
                        .param("size", String.valueOf(size)))
                .andExpect(jsonPath("$.last").value(true))
                .andExpect(jsonPath("$.hasNext").value(false));
    }

    @Test
    void pagePastTheEndIsEmptyNotAnError() throws Exception {
        mockMvc.perform(get("/api/vehicles").param("page", "9999").param("size", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content").isEmpty())
                .andExpect(jsonPath("$.number").value(9999))
                .andExpect(jsonPath("$.last").value(true))
                .andExpect(jsonPath("$.hasNext").value(false));
    }

    @Test
    void searchAndStatusCombineAndCountsAgreeWithTheList() throws Exception {
        Vehicle a = vehicle("TEST-IT-GA-11-0101");
        a.setDriverName("Zebulon Qwerty");
        a.setStatus(VehicleStatus.MAINTENANCE);
        Vehicle b = vehicle("TEST-IT-GA-11-0102");
        b.setCompany("Qwerty Freight");
        b.setStatus(VehicleStatus.AVAILABLE);
        Vehicle c = vehicle("TEST-IT-GA-11-0103");
        c.setStatus(VehicleStatus.MAINTENANCE);
        repository.save(a);
        repository.save(b);
        repository.save(c);

        mockMvc.perform(get("/api/vehicles").param("q", "QWERTY").param("size", "100"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(2));
        mockMvc.perform(get("/api/vehicles").param("q", "qwerty").param("status", "maintenance"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(1))
                .andExpect(jsonPath("$.content[0].vehicleNumber").value("TEST-IT-GA-11-0101"));
        mockMvc.perform(get("/api/vehicles/status-counts").param("q", "qwerty"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.MAINTENANCE").value(1))
                .andExpect(jsonPath("$.AVAILABLE").value(1))
                .andExpect(jsonPath("$.IN_USE").value(0))
                .andExpect(jsonPath("$.INACTIVE").value(0));
    }

    @Test
    void searchTreatsWildcardsAsPlainText() throws Exception {
        repository.save(vehicle("TEST-IT-GA-11-0201"));
        mockMvc.perform(get("/api/vehicles").param("q", "%"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(0));
        mockMvc.perform(get("/api/vehicles").param("q", "test-it-ga-11-02_1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(0));
    }

    @Test
    void unknownStatusAndOverlongSearchAreRejectedWith400() throws Exception {
        mockMvc.perform(get("/api/vehicles").param("status", "NOPE"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errors.status").value("Status must be one of [AVAILABLE, IN_USE, MAINTENANCE, INACTIVE]"));
        mockMvc.perform(get("/api/vehicles/status-counts").param("q", "x".repeat(101)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errors.q").value("Search text must be 100 characters or fewer"));
    }

    private static Vehicle vehicle(String number) {
        Vehicle v = new Vehicle();
        v.setVehicleNumber(number);
        v.setVehicleType(VehicleType.CAR);
        v.setBrand("Toyota");
        v.setModel("Axio");
        v.setFuelType(FuelType.HYBRID);
        return v;
    }
}
