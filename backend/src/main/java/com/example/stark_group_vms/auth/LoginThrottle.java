package com.example.stark_group_vms.auth;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

/**
 * Slows down password guessing: after {@value #MAX_FAILURES} wrong passwords for the same
 * username from the same address, that pair is refused for {@link #LOCK}. Keyed by username AND
 * address so an attacker can't lock the real admin out from elsewhere.
 * shortcut: in-memory, so it resets on restart and isn't shared between servers; move to the
 * database or Redis if the API ever runs on more than one instance.
 */
@Component
public class LoginThrottle {

    static final int MAX_FAILURES = 5;
    static final Duration LOCK = Duration.ofMinutes(15);
    private static final int MAX_TRACKED = 10_000;

    private record Attempts(int failures, Instant lockedUntil) {
    }

    private final Map<String, Attempts> attempts = new ConcurrentHashMap<>();
    private final Clock clock;

    @Autowired
    public LoginThrottle() {
        this(Clock.systemUTC());
    }

    LoginThrottle(Clock clock) {
        this.clock = clock;
    }

    /** Minutes the caller must still wait, or 0 when they may try. */
    public long minutesLocked(String username, String address) {
        Attempts a = attempts.get(key(username, address));
        if (a == null || a.lockedUntil() == null) {
            return 0;
        }
        Duration left = Duration.between(clock.instant(), a.lockedUntil());
        if (left.isNegative() || left.isZero()) {
            attempts.remove(key(username, address));
            return 0;
        }
        return Math.max(1, (left.toSeconds() + 59) / 60);
    }

    public void recordFailure(String username, String address) {
        if (attempts.size() > MAX_TRACKED) {
            Instant now = clock.instant();
            attempts.values().removeIf(a -> a.lockedUntil() == null || a.lockedUntil().isBefore(now));
        }
        attempts.compute(key(username, address), (k, a) -> {
            int failures = (a == null ? 0 : a.failures()) + 1;
            Instant lockedUntil = failures >= MAX_FAILURES ? clock.instant().plus(LOCK) : null;
            return new Attempts(failures, lockedUntil);
        });
    }

    public void recordSuccess(String username, String address) {
        attempts.remove(key(username, address));
    }

    private static String key(String username, String address) {
        return username.trim().toLowerCase() + "|" + address;
    }
}
