package com.tracker.expense.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tracker.expense.common.exception.BadRequestException;
import com.tracker.expense.config.SecurityConfig;
import com.tracker.expense.dto.AuthResponse;
import com.tracker.expense.dto.LoginRequest;
import com.tracker.expense.dto.RegisterRequest;
import com.tracker.expense.dto.UserResponse;
import com.tracker.expense.security.CustomUserDetailsService;
import com.tracker.expense.security.JwtAuthenticationEntryPoint;
import com.tracker.expense.security.JwtAuthenticationFilter;
import com.tracker.expense.security.JwtService;
import com.tracker.expense.service.AuthService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.cookie;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = {AuthController.class, UserController.class})
@Import({SecurityConfig.class, JwtAuthenticationEntryPoint.class, JwtAuthenticationFilter.class, com.tracker.expense.config.ClockConfig.class})
class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private AuthService authService;

    @MockBean
    private JwtService jwtService;

    @MockBean
    private CustomUserDetailsService userDetailsService;

    @Test
    void register_validRequest_shouldReturn201CreatedAndSetCookie() throws Exception {
        RegisterRequest request = RegisterRequest.builder()
                .email("test@example.com")
                .password("Password123!")
                .fullName("Test User")
                .currency("VND")
                .timezone("Asia/Ho_Chi_Minh")
                .build();

        AuthResponse authResponse = AuthResponse.builder()
                .accessToken("access-token-123")
                .refreshToken("refresh-token-123")
                .tokenType("Bearer")
                .expiresIn(900000L)
                .user(UserResponse.builder()
                        .id(UUID.randomUUID())
                        .email("test@example.com")
                        .fullName("Test User")
                        .currency("VND")
                        .timezone("Asia/Ho_Chi_Minh")
                        .createdAt(Instant.now())
                        .build())
                .build();

        when(authService.register(any(RegisterRequest.class))).thenReturn(authResponse);

        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.accessToken").value("access-token-123"))
                .andExpect(jsonPath("$.refreshToken").value("refresh-token-123"))
                .andExpect(jsonPath("$.user.email").value("test@example.com"))
                .andExpect(header().exists("Set-Cookie"))
                .andExpect(cookie().value("refresh_token", "refresh-token-123"));
    }

    @Test
    void register_shortPassword_shouldReturn422UnprocessableEntity() throws Exception {
        RegisterRequest request = RegisterRequest.builder()
                .email("test@example.com")
                .password("short")
                .fullName("Test User")
                .build();

        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.status").value(422))
                .andExpect(jsonPath("$.details.password").exists());
    }

    @Test
    void register_duplicateEmail_shouldReturn400BadRequest() throws Exception {
        RegisterRequest request = RegisterRequest.builder()
                .email("test@example.com")
                .password("Password123!")
                .fullName("Test User")
                .build();

        when(authService.register(any(RegisterRequest.class)))
                .thenThrow(new BadRequestException("Email is already registered"));

        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Email is already registered"));
    }

    @Test
    void login_validCredentials_shouldReturn200Ok() throws Exception {
        LoginRequest request = LoginRequest.builder()
                .email("test@example.com")
                .password("Password123!")
                .build();

        AuthResponse authResponse = AuthResponse.builder()
                .accessToken("access-token-123")
                .refreshToken("refresh-token-123")
                .tokenType("Bearer")
                .expiresIn(900000L)
                .user(UserResponse.builder()
                        .id(UUID.randomUUID())
                        .email("test@example.com")
                        .fullName("Test User")
                        .build())
                .build();

        when(authService.login(any(LoginRequest.class))).thenReturn(authResponse);

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").value("access-token-123"))
                .andExpect(cookie().value("refresh_token", "refresh-token-123"));
    }

    @Test
    void login_badCredentials_shouldReturn401Unauthorized() throws Exception {
        LoginRequest request = LoginRequest.builder()
                .email("test@example.com")
                .password("WrongPassword")
                .build();

        when(authService.login(any(LoginRequest.class)))
                .thenThrow(new BadCredentialsException("Invalid email or password"));

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Invalid email or password"));
    }

    @Test
    void logout_shouldClearCookie() throws Exception {
        mockMvc.perform(post("/api/v1/auth/logout"))
                .andExpect(status().isOk())
                .andExpect(cookie().maxAge("refresh_token", 0))
                .andExpect(jsonPath("$.message").value("Logged out successfully"));
    }

    @Test
    void getMe_withoutAuthToken_shouldReturn401Unauthorized() throws Exception {
        mockMvc.perform(get("/api/v1/me"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.status").value(401))
                .andExpect(jsonPath("$.error").value("Unauthorized"));
    }
}
