package com.tracker.expense.security;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class JwtServiceTest {

    private JwtService jwtService;

    @BeforeEach
    void setUp() {
        jwtService = new JwtService();
        ReflectionTestUtils.setField(jwtService, "jwtSecret", "404E635266556A586E3272357538782F413F4428472B4B6250645367566B5970");
        ReflectionTestUtils.setField(jwtService, "accessTokenExpirationMs", 900000L);
        ReflectionTestUtils.setField(jwtService, "refreshTokenExpirationMs", 604800000L);
    }

    @Test
    void validateSecret_refusesMissingOrShortSecrets() {
        JwtService service = new JwtService();
        ReflectionTestUtils.setField(service, "jwtSecret", null);
        assertThrows(IllegalStateException.class, service::validateSecret);

        // Previously a short secret was silently stretched with SHA-256 and accepted.
        ReflectionTestUtils.setField(service, "jwtSecret", "too-short");
        assertThrows(IllegalStateException.class, service::validateSecret);

        assertDoesNotThrow(jwtService::validateSecret);
    }

    @Test
    void generateAccessToken_shouldContainValidClaims() {
        UUID userId = UUID.randomUUID();
        String email = "test@example.com";

        String token = jwtService.generateAccessToken(userId, email);

        assertNotNull(token);
        assertTrue(jwtService.validateToken(token));
        assertFalse(jwtService.isRefreshToken(token));
        assertEquals(userId, jwtService.extractUserId(token));
        assertEquals(email, jwtService.extractEmail(token));
    }

    @Test
    void generateRefreshToken_shouldBeIdentifiedAsRefreshToken() {
        UUID userId = UUID.randomUUID();

        String refreshToken = jwtService.generateRefreshToken(userId);

        assertNotNull(refreshToken);
        assertTrue(jwtService.validateToken(refreshToken));
        assertTrue(jwtService.isRefreshToken(refreshToken));
        assertEquals(userId, jwtService.extractUserId(refreshToken));
    }

    @Test
    void validateToken_shouldReturnFalseForInvalidToken() {
        assertFalse(jwtService.validateToken("invalid.token.string"));
    }
}
