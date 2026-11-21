package com.example.stark_group_vms.auth;

/** 429: too many wrong passwords from this address for this username. */
public class TooManyAttemptsException extends RuntimeException {

    public TooManyAttemptsException(long minutes) {
        super("Too many failed sign-in attempts. Try again in " + minutes
                + (minutes == 1 ? " minute" : " minutes") + ".");
    }
}
