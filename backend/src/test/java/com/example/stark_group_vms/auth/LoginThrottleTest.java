package com.example.stark_group_vms.auth;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import org.junit.jupiter.api.Test;

class LoginThrottleTest {

    /** A clock the test can move forward. */
    private static final class MovableClock extends Clock {
        private Instant now = Instant.parse("2026-11-21T10:00:00Z");
        void advance(Duration d) { now = now.plus(d); }
        @Override public ZoneId getZone() { return ZoneId.of("UTC"); }
        @Override public Clock withZone(ZoneId zone) { return this; }
        @Override public Instant instant() { return now; }
    }

    @Test
    void locksAfterFiveFailuresAndUnlocksAfterFifteenMinutes() {
        MovableClock clock = new MovableClock();
        LoginThrottle throttle = new LoginThrottle(clock);

        for (int i = 0; i < 4; i++) {
            throttle.recordFailure("Admin", "1.2.3.4");
        }
        assertThat(throttle.minutesLocked("admin", "1.2.3.4")).isZero();

        throttle.recordFailure("ADMIN", "1.2.3.4");
        assertThat(throttle.minutesLocked("admin", "1.2.3.4")).isEqualTo(15);
        assertThat(throttle.minutesLocked("admin", "5.6.7.8")).isZero();

        clock.advance(Duration.ofMinutes(14).plusSeconds(1));
        assertThat(throttle.minutesLocked("admin", "1.2.3.4")).isEqualTo(1);

        clock.advance(Duration.ofSeconds(60));
        assertThat(throttle.minutesLocked("admin", "1.2.3.4")).isZero();
    }

    @Test
    void successClearsEarlierFailures() {
        LoginThrottle throttle = new LoginThrottle(new MovableClock());
        for (int i = 0; i < 4; i++) {
            throttle.recordFailure("admin", "1.2.3.4");
        }
        throttle.recordSuccess("admin", "1.2.3.4");
        throttle.recordFailure("admin", "1.2.3.4");
        assertThat(throttle.minutesLocked("admin", "1.2.3.4")).isZero();
    }
}
