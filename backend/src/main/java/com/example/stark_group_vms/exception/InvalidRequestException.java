package com.example.stark_group_vms.exception;

import java.util.Map;

/** A request we understood but refuse (400). The message is safe to show to the user. */
public class InvalidRequestException extends RuntimeException {

    private final Map<String, String> fieldErrors;

    public InvalidRequestException(String message) {
        this(message, Map.of());
    }

    public InvalidRequestException(String message, Map<String, String> fieldErrors) {
        super(message);
        this.fieldErrors = fieldErrors;
    }

    public Map<String, String> getFieldErrors() {
        return fieldErrors;
    }
}
