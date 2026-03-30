package com.buzzer.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public sealed interface AuthDtos {

    record RegisterRequest(
            @NotBlank(message = "Username is required")
            @Size(min = 3, max = 50, message = "Username must be between 3 and 50 characters")
            @Pattern(regexp = "^[a-z0-9_]+$", message = "Username can only contain lowercase letters, numbers, and underscores")
            String username,

            @NotBlank(message = "Email is required")
            @Email(message = "Invalid email format")
            String email,

            @NotBlank(message = "Password is required")
            @Size(min = 8, max = 100, message = "Password must be between 8 and 100 characters")
            String password,

            @NotBlank(message = "Display name is required")
            @Size(min = 1, max = 100, message = "Display name must be between 1 and 100 characters")
            String displayName
    ) implements AuthDtos {}

    record LoginRequest(
            @NotBlank(message = "Email is required")
            @Email(message = "Invalid email format")
            String email,

            @NotBlank(message = "Password is required")
            String password
    ) implements AuthDtos {}

    record RefreshRequest(
            @NotBlank(message = "Refresh token is required")
            String refreshToken
    ) implements AuthDtos {}

    record AuthResponse(
            String accessToken,
            String refreshToken,
            UserDto user
    ) implements AuthDtos {}

    record UserDto(
            java.util.UUID id,
            String username,
            String email,
            String displayName,
            String avatarUrl
    ) implements AuthDtos {}
}