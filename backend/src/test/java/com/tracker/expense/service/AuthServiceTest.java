package com.tracker.expense.service;

import com.tracker.expense.common.exception.BadRequestException;
import com.tracker.expense.common.exception.UnauthorizedException;
import com.tracker.expense.dto.AuthResponse;
import com.tracker.expense.dto.LoginRequest;
import com.tracker.expense.dto.RefreshTokenRequest;
import com.tracker.expense.dto.RegisterRequest;
import com.tracker.expense.model.User;
import com.tracker.expense.repository.CategoryRepository;
import com.tracker.expense.repository.PaymentMethodRepository;
import com.tracker.expense.repository.UserRepository;
import com.tracker.expense.security.JwtService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private CategoryRepository categoryRepository;

    @Mock
    private PaymentMethodRepository paymentMethodRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtService jwtService;

    @InjectMocks
    private AuthService authService;

    private User sampleUser;
    private final UUID userId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        sampleUser = User.builder()
                .id(userId)
                .email("user@example.com")
                .passwordHash("$2a$10$hashedPassword")
                .fullName("Test User")
                .currency("VND")
                .timezone("Asia/Ho_Chi_Minh")
                .createdAt(Instant.now())
                .build();
    }

    @Test
    void register_success_shouldSaveUserAndSeedDefaultCategoriesAndReturnTokens() {
        RegisterRequest request = RegisterRequest.builder()
                .email("user@example.com")
                .password("Password123!")
                .fullName("Test User")
                .currency("VND")
                .timezone("Asia/Ho_Chi_Minh")
                .build();

        when(userRepository.existsByEmail("user@example.com")).thenReturn(false);
        when(passwordEncoder.encode("Password123!")).thenReturn("$2a$10$hashedPassword");
        when(userRepository.save(any(User.class))).thenReturn(sampleUser);
        when(jwtService.generateAccessToken(eq(userId), eq("user@example.com"))).thenReturn("access-token-123");
        when(jwtService.generateRefreshToken(eq(userId))).thenReturn("refresh-token-123");
        when(jwtService.getAccessTokenExpirationMs()).thenReturn(900000L);

        AuthResponse response = authService.register(request);

        assertNotNull(response);
        assertEquals("access-token-123", response.getAccessToken());
        assertEquals("refresh-token-123", response.getRefreshToken());
        assertEquals("user@example.com", response.getUser().getEmail());

        verify(categoryRepository).saveAll(anyList());
        verify(paymentMethodRepository).saveAll(anyList());
    }

    @Test
    void register_duplicateEmail_shouldThrowBadRequestException() {
        RegisterRequest request = RegisterRequest.builder()
                .email("user@example.com")
                .password("Password123!")
                .fullName("Test User")
                .build();

        when(userRepository.existsByEmail("user@example.com")).thenReturn(true);

        assertThrows(BadRequestException.class, () -> authService.register(request));
        verify(userRepository, never()).save(any(User.class));
    }

    @Test
    void login_success_shouldReturnAuthResponse() {
        LoginRequest request = LoginRequest.builder()
                .email("user@example.com")
                .password("Password123!")
                .build();

        when(userRepository.findByEmail("user@example.com")).thenReturn(Optional.of(sampleUser));
        when(passwordEncoder.matches("Password123!", sampleUser.getPasswordHash())).thenReturn(true);
        when(jwtService.generateAccessToken(eq(userId), eq("user@example.com"))).thenReturn("access-token-123");
        when(jwtService.generateRefreshToken(eq(userId))).thenReturn("refresh-token-123");
        when(jwtService.getAccessTokenExpirationMs()).thenReturn(900000L);

        AuthResponse response = authService.login(request);

        assertNotNull(response);
        assertEquals("access-token-123", response.getAccessToken());
        assertEquals("refresh-token-123", response.getRefreshToken());
    }

    @Test
    void login_wrongPassword_shouldThrowBadCredentialsException() {
        LoginRequest request = LoginRequest.builder()
                .email("user@example.com")
                .password("WrongPassword")
                .build();

        when(userRepository.findByEmail("user@example.com")).thenReturn(Optional.of(sampleUser));
        when(passwordEncoder.matches("WrongPassword", sampleUser.getPasswordHash())).thenReturn(false);

        assertThrows(BadCredentialsException.class, () -> authService.login(request));
    }

    @Test
    void refreshToken_validToken_shouldReturnRotatedTokens() {
        RefreshTokenRequest request = new RefreshTokenRequest("valid-refresh-token");

        when(jwtService.validateToken("valid-refresh-token")).thenReturn(true);
        when(jwtService.isRefreshToken("valid-refresh-token")).thenReturn(true);
        when(jwtService.extractUserId("valid-refresh-token")).thenReturn(userId);
        when(userRepository.findById(userId)).thenReturn(Optional.of(sampleUser));
        when(jwtService.generateAccessToken(eq(userId), eq("user@example.com"))).thenReturn("new-access-token");
        when(jwtService.generateRefreshToken(eq(userId))).thenReturn("new-refresh-token");
        when(jwtService.getAccessTokenExpirationMs()).thenReturn(900000L);

        AuthResponse response = authService.refreshToken(request);

        assertNotNull(response);
        assertEquals("new-access-token", response.getAccessToken());
        assertEquals("new-refresh-token", response.getRefreshToken());
    }

    @Test
    void refreshToken_invalidToken_shouldThrowUnauthorizedException() {
        RefreshTokenRequest request = new RefreshTokenRequest("invalid-refresh-token");

        when(jwtService.validateToken("invalid-refresh-token")).thenReturn(false);

        assertThrows(UnauthorizedException.class, () -> authService.refreshToken(request));
    }
}
