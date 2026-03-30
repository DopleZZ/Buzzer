package com.buzzer.auth.service;

import com.buzzer.auth.dto.AuthDtos;
import com.buzzer.auth.entity.RefreshToken;
import com.buzzer.auth.repository.RefreshTokenRepository;
import com.buzzer.common.exception.BusinessException;
import com.buzzer.common.exception.EntityAlreadyExistsException;
import com.buzzer.common.exception.EntityNotFoundException;
import com.buzzer.user.entity.User;
import com.buzzer.user.entity.UserStatus;
import com.buzzer.user.repository.UserRepository;
import io.github.resilience4j.ratelimiter.annotation.RateLimiter;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final JwtService jwtService;
    private final PasswordEncoder passwordEncoder;

    @Transactional
    public AuthDtos.AuthResponse register(AuthDtos.RegisterRequest request) {
        if (userRepository.existsByEmail(request.email())) {
            throw new EntityAlreadyExistsException("Email already registered", "email");
        }

        if (userRepository.existsByUsername(request.username())) {
            throw new EntityAlreadyExistsException("Username already taken", "username");
        }

        User user = new User();
        user.setUsername(request.username());
        user.setEmail(request.email());
        user.setPasswordHash(passwordEncoder.encode(request.password()));
        user.setDisplayName(request.displayName());
        user.setStatus(UserStatus.ACTIVE);

        user = userRepository.save(user);

        String accessToken = jwtService.generateAccessToken(
                new UserDetailsAdapter(user),
                user.getId()
        );
        UUID refreshTokenValue = createRefreshToken(user);

        return new AuthDtos.AuthResponse(
                accessToken,
                refreshTokenValue.toString(),
                toUserDto(user)
        );
    }

    @RateLimiter(name = "auth-login")
    @Transactional
    public AuthDtos.AuthResponse login(AuthDtos.LoginRequest request) {
        User user = userRepository.findByEmail(request.email())
                .orElseThrow(() -> new EntityNotFoundException("Invalid email or password"));

        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new EntityNotFoundException("Invalid email or password");
        }

        if (user.getStatus() == UserStatus.BLOCKED) {
            throw new BusinessException("User account is blocked");
        }

        String accessToken = jwtService.generateAccessToken(
                new UserDetailsAdapter(user),
                user.getId()
        );
        UUID refreshTokenValue = createRefreshToken(user);

        return new AuthDtos.AuthResponse(
                accessToken,
                refreshTokenValue.toString(),
                toUserDto(user)
        );
    }

    @Transactional
    public AuthDtos.AuthResponse refresh(AuthDtos.RefreshRequest request) {
        UUID refreshTokenId;
        try {
            refreshTokenId = UUID.fromString(request.refreshToken());
        } catch (IllegalArgumentException e) {
            throw new BusinessException("Invalid refresh token format");
        }

        String tokenHash = jwtService.hashRefreshToken(refreshTokenId);
        RefreshToken refreshToken = refreshTokenRepository.findByTokenHash(tokenHash)
                .orElseThrow(() -> new BusinessException("Invalid refresh token"));

        if (refreshToken.isRevoked()) {
            // Potential reuse attack - invalidate all tokens
            refreshTokenRepository.deleteAllByUser(refreshToken.getUser());
            throw new BusinessException("Refresh token has been revoked. Please login again.");
        }

        if (refreshToken.isExpired()) {
            throw new BusinessException("Refresh token has expired. Please login again.");
        }

        // Revoke old token
        refreshToken.setRevokedAt(OffsetDateTime.now());
        refreshTokenRepository.save(refreshToken);

        // Create new token
        User user = refreshToken.getUser();
        UUID newRefreshTokenValue = createRefreshToken(user);
        String newAccessToken = jwtService.generateAccessToken(
                new UserDetailsAdapter(user),
                user.getId()
        );

        return new AuthDtos.AuthResponse(
                newAccessToken,
                newRefreshTokenValue.toString(),
                toUserDto(user)
        );
    }

    @Transactional
    public void logout(String refreshTokenValue, User user) {
        UUID tokenId;
        try {
            tokenId = UUID.fromString(refreshTokenValue);
        } catch (IllegalArgumentException e) {
            return; // Invalid token, just ignore
        }

        String tokenHash = jwtService.hashRefreshToken(tokenId);
        refreshTokenRepository.findByTokenHash(tokenHash)
                .ifPresent(token -> {
                    if (token.getUser().getId().equals(user.getId())) {
                        token.setRevokedAt(OffsetDateTime.now());
                        refreshTokenRepository.save(token);
                    }
                });
    }

    @Transactional
    public void logoutAll(User user) {
        refreshTokenRepository.deleteAllByUser(user);
    }

    public AuthDtos.UserDto getCurrentUser(User user) {
        return toUserDto(user);
    }

    private UUID createRefreshToken(User user) {
        UUID tokenValue = jwtService.generateRefreshToken();
        String tokenHash = jwtService.hashRefreshToken(tokenValue);

        RefreshToken refreshToken = new RefreshToken();
        refreshToken.setUser(user);
        refreshToken.setTokenHash(tokenHash);
        refreshToken.setExpiresAt(OffsetDateTime.now().plus(jwtService.getRefreshTokenTtl()));

        refreshTokenRepository.save(refreshToken);
        return tokenValue;
    }

    private AuthDtos.UserDto toUserDto(User user) {
        return new AuthDtos.UserDto(
                user.getId(),
                user.getUsername(),
                user.getEmail(),
                user.getDisplayName(),
                user.getAvatarUrl()
        );
    }

    private static class UserDetailsAdapter implements org.springframework.security.core.userdetails.UserDetails {
        private final User user;

        UserDetailsAdapter(User user) {
            this.user = user;
        }

        @Override
        public String getUsername() {
            return user.getUsername();
        }

        @Override
        public String getPassword() {
            return user.getPasswordHash();
        }

        @Override
        public java.util.Collection<? extends org.springframework.security.core.GrantedAuthority> getAuthorities() {
            return java.util.Collections.singletonList(
                    new org.springframework.security.core.authority.SimpleGrantedAuthority("ROLE_USER")
            );
        }

        @Override
        public boolean isAccountNonExpired() { return true; }

        @Override
        public boolean isAccountNonLocked() { return user.getStatus() != UserStatus.BLOCKED; }

        @Override
        public boolean isCredentialsNonExpired() { return true; }

        @Override
        public boolean isEnabled() { return user.getStatus() == UserStatus.ACTIVE; }
    }
}