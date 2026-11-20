package com.example.stark_group_vms.auth;

import com.example.stark_group_vms.entity.AppUser;
import com.example.stark_group_vms.repository.AppUserRepository;
import java.security.SecureRandom;
import java.util.Base64;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * Creates the first admin when nobody can sign in yet. There is no public sign-up (ADR-0005).
 * With ADMIN_PASSWORD unset, a random password is generated and printed once, so no password
 * ever lives in the code.
 */
@Component
@ConditionalOnProperty(name = "app.admin.seed", havingValue = "true", matchIfMissing = true)
public class AdminSeeder implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(AdminSeeder.class);
    static final int MIN_PASSWORD_LENGTH = 12;

    private final AppUserRepository users;
    private final PasswordEncoder passwordEncoder;
    private final String username;
    private final String password;

    public AdminSeeder(AppUserRepository users, PasswordEncoder passwordEncoder,
                       @Value("${app.admin.username:admin}") String username,
                       @Value("${app.admin.password:}") String password) {
        this.users = users;
        this.passwordEncoder = passwordEncoder;
        this.username = username.trim();
        this.password = password;
    }

    @Override
    public void run(String... args) {
        if (users.count() > 0) {
            return;
        }
        boolean generated = password == null || password.isBlank();
        if (!generated && password.length() < MIN_PASSWORD_LENGTH) {
            throw new IllegalStateException("ADMIN_PASSWORD must be at least " + MIN_PASSWORD_LENGTH + " characters");
        }
        String chosen = generated ? randomPassword() : password;
        users.save(new AppUser(username, passwordEncoder.encode(chosen)));

        if (generated) {
            log.warn("Created admin '{}' with generated password: {}  (shown once; set ADMIN_PASSWORD to choose your own)",
                    username, chosen);
        } else {
            log.info("Created admin '{}' with the password from ADMIN_PASSWORD", username);
        }
    }

    private static String randomPassword() {
        byte[] bytes = new byte[15];
        new SecureRandom().nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }
}
