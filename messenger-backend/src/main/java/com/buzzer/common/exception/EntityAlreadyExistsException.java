package com.buzzer.common.exception;

import lombok.Getter;

@Getter
public class EntityAlreadyExistsException extends RuntimeException {
    private final String field;

    public EntityAlreadyExistsException(String message, String field) {
        super(message);
        this.field = field;
    }
}