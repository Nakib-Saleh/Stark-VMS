package com.example.stark_group_vms.exception;

/** 409. {@code field} names the request field at fault, so the client can show the error next to it. */
public class DuplicateResourceException extends RuntimeException {

    private final String field;

    public DuplicateResourceException(String message) {
        this(null, message);
    }

    public DuplicateResourceException(String field, String message) {
        super(message);
        this.field = field;
    }

    public String getField() {
        return field;
    }
}
