package com.buzzer.auth.repository;

import com.buzzer.auth.entity.RefreshToken;
import com.buzzer.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface RefreshTokenRepository extends JpaRepository<RefreshToken, UUID> {

    Optional<RefreshToken> findByTokenHash(String tokenHash);

    void deleteAllByUser(User user);

    long countByUserAndRevokedAtIsNull(User user);
}