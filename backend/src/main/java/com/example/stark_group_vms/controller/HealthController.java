package com.example.stark_group_vms.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Answers as soon as the app is running. Render uses it to decide a deploy is live, and the web
 * app calls it to tell "server waking up" apart from "server unreachable". Open to anyone, so it
 * reveals nothing (no version, no database state).
 */
@RestController
public class HealthController {

    public record HealthResponse(String status) {
    }

    @GetMapping("/api/health")
    public HealthResponse health() {
        return new HealthResponse("up");
    }
}
