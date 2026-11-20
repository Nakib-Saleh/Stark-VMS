package com.example.stark_group_vms.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.example.stark_group_vms.entity.AppUser;
import com.example.stark_group_vms.repository.AppUserRepository;
import com.example.stark_group_vms.repository.VehicleRepository;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/** Sign-in and access rules, tested as an outsider first (CLAUDE.md §6). Real MySQL. */
@SpringBootTest(properties = "app.admin.seed=false")
@AutoConfigureMockMvc
class AuthIntegrationTest {

    private static final String PASSWORD = "correct-horse-battery";
    private static final String BODY = """
            {"vehicleNumber": "TEST-IT-AUTH-1", "vehicleType": "CAR", "brand": "X", "model": "Y", "fuelType": "HYBRID"}
            """;

    @Autowired private MockMvc mockMvc;
    @Autowired private AppUserRepository users;
    @Autowired private VehicleRepository vehicles;
    @Autowired private PasswordEncoder passwordEncoder;
    @Autowired private JwtEncoder jwtEncoder;

    private String username;

    @BeforeEach
    void createUser() {
        // A fresh name per test so throttle state from one test can't leak into another.
        username = "test-it-" + System.nanoTime();
        users.save(new AppUser(username, passwordEncoder.encode(PASSWORD)));
    }

    @AfterEach
    void cleanUp() {
        users.findAll().stream().filter(u -> u.getUsername().startsWith("test-it-")).forEach(users::delete);
    }

    private static MockHttpServletRequestBuilder from(MockHttpServletRequestBuilder b, String address) {
        return b.with(r -> { r.setRemoteAddr(address); return r; });
    }

    private MockHttpServletRequestBuilder login(String user, String password) {
        return post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content("{\"username\": \"" + user + "\", \"password\": \"" + password + "\"}");
    }

    private String token() throws Exception {
        String json = mockMvc.perform(login(username, PASSWORD)).andReturn().getResponse().getContentAsString();
        Matcher m = Pattern.compile("\"token\":\"([^\"]+)\"").matcher(json);
        assertThat(m.find()).as("login response has a token: %s", json).isTrue();
        return m.group(1);
    }

    @Test
    void everyVehicleEndpointRefusesAnAnonymousCaller() throws Exception {
        long before = vehicles.count();
        for (MockHttpServletRequestBuilder request : new MockHttpServletRequestBuilder[] {
                get("/api/vehicles"),
                get("/api/vehicles/1"),
                post("/api/vehicles").contentType(MediaType.APPLICATION_JSON).content(BODY),
                put("/api/vehicles/1").contentType(MediaType.APPLICATION_JSON).content(BODY),
                delete("/api/vehicles/1"),
                get("/api/auth/me")}) {
            mockMvc.perform(request)
                    .andExpect(status().isUnauthorized())
                    .andExpect(jsonPath("$.status").value(401))
                    .andExpect(jsonPath("$.message").value("Sign in to continue"));
        }
        assertThat(vehicles.count()).isEqualTo(before);
    }

    @Test
    void madeUpTamperedAndExpiredTokensAreRefused() throws Exception {
        String good = token();
        String tampered = good.substring(0, good.length() - 2) + (good.endsWith("A") ? "BB" : "AA");
        Instant past = Instant.now().minus(2, ChronoUnit.HOURS);
        String expired = jwtEncoder.encode(JwtEncoderParameters.from(JwsHeader.with(MacAlgorithm.HS256).build(),
                JwtClaimsSet.builder().subject(username).issuedAt(past.minus(1, ChronoUnit.HOURS))
                        .expiresAt(past).build())).getTokenValue();

        for (String bad : new String[] {"abc", tampered, expired}) {
            mockMvc.perform(get("/api/vehicles").header("Authorization", "Bearer " + bad))
                    .andExpect(status().isUnauthorized())
                    .andExpect(jsonPath("$.message").value("Sign in to continue"));
        }
    }

    @Test
    void wrongPasswordAndUnknownUserGetTheSameAnswer() throws Exception {
        mockMvc.perform(login(username, "wrong-password"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value(AuthController.BAD_CREDENTIALS));
        mockMvc.perform(login("test-it-nobody", PASSWORD))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value(AuthController.BAD_CREDENTIALS));
    }

    @Test
    void correctLoginGivesATokenThatOpensTheApi() throws Exception {
        mockMvc.perform(login(username.toUpperCase(), PASSWORD))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.username").value(username))
                .andExpect(jsonPath("$.expiresAt").exists());

        String token = token();
        mockMvc.perform(get("/api/vehicles").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk());
        mockMvc.perform(get("/api/auth/me").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.username").value(username));
    }

    @Test
    void fiveWrongPasswordsLockThatAddressButNotOthers() throws Exception {
        for (int i = 0; i < LoginThrottle.MAX_FAILURES; i++) {
            mockMvc.perform(from(login(username, "wrong"), "10.9.9.1")).andExpect(status().isUnauthorized());
        }
        mockMvc.perform(from(login(username, PASSWORD), "10.9.9.1"))
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.message").value("Too many failed sign-in attempts. Try again in 15 minutes."));
        mockMvc.perform(from(login(username, PASSWORD), "10.9.9.2"))
                .andExpect(status().isOk());
    }

    @Test
    void missingFieldsGetFieldMessages() throws Exception {
        mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errors.username").value("Enter your username"))
                .andExpect(jsonPath("$.errors.password").value("Enter your password"));
    }
}
