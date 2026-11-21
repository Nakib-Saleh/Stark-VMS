package com.example.stark_group_vms.auth;

import com.example.stark_group_vms.entity.AppUser;
import com.example.stark_group_vms.repository.AppUserRepository;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    /** Same wording for wrong password and unknown username, so the reply doesn't reveal which. */
    static final String BAD_CREDENTIALS = "That username and password don't match";

    public record LoginRequest(
            @NotBlank(message = "Enter your username") @Size(max = 50, message = "Username is too long") String username,
            @NotBlank(message = "Enter your password") @Size(max = 200, message = "Password is too long") String password) {
    }

    public record LoginResponse(String token, Instant expiresAt, String username) {
    }

    private final AppUserRepository users;
    private final PasswordEncoder passwordEncoder;
    private final JwtEncoder jwtEncoder;
    private final LoginThrottle throttle;
    private final Duration ttl;
    private final String dummyHash;

    public AuthController(AppUserRepository users, PasswordEncoder passwordEncoder, JwtEncoder jwtEncoder,
                          LoginThrottle throttle, @Value("${app.jwt.ttl:PT8H}") Duration ttl) {
        this.users = users;
        this.passwordEncoder = passwordEncoder;
        this.jwtEncoder = jwtEncoder;
        this.throttle = throttle;
        this.ttl = ttl;
        // Checked against when the username doesn't exist, so both cases take the same time.
        this.dummyHash = passwordEncoder.encode("timing-equaliser");
    }

    @PostMapping("/login")
    public LoginResponse login(@Valid @RequestBody LoginRequest request, HttpServletRequest http) {
        String address = http.getRemoteAddr();
        long wait = throttle.minutesLocked(request.username(), address);
        if (wait > 0) {
            throw new TooManyAttemptsException(wait);
        }

        Optional<AppUser> user = users.findByUsernameIgnoreCase(request.username().trim());
        boolean matches = passwordEncoder.matches(request.password(),
                user.map(AppUser::getPasswordHash).orElse(dummyHash));
        if (user.isEmpty() || !matches) {
            throttle.recordFailure(request.username(), address);
            throw new BadCredentialsException(BAD_CREDENTIALS);
        }
        throttle.recordSuccess(request.username(), address);

        String username = user.get().getUsername();
        Instant now = Instant.now();
        Instant expiresAt = now.plus(ttl);
        JwtClaimsSet claims = JwtClaimsSet.builder()
                .issuer("stark-vms")
                .subject(username)
                .issuedAt(now)
                .expiresAt(expiresAt)
                .build();
        String token = jwtEncoder.encode(JwtEncoderParameters.from(
                JwsHeader.with(MacAlgorithm.HS256).build(), claims)).getTokenValue();
        return new LoginResponse(token, expiresAt, username);
    }

    @GetMapping("/me")
    public Map<String, String> me(@AuthenticationPrincipal Jwt jwt) {
        return Map.of("username", jwt.getSubject());
    }
}
