package com.tracker.expense.service;

import com.tracker.expense.common.exception.BadRequestException;
import com.tracker.expense.common.exception.ResourceNotFoundException;
import com.tracker.expense.common.exception.UnauthorizedException;
import com.tracker.expense.dto.AuthResponse;
import com.tracker.expense.dto.LoginRequest;
import com.tracker.expense.dto.RefreshTokenRequest;
import com.tracker.expense.dto.RegisterRequest;
import com.tracker.expense.dto.UpdateProfileRequest;
import com.tracker.expense.dto.UserResponse;
import com.tracker.expense.model.Category;
import com.tracker.expense.model.PaymentMethod;
import com.tracker.expense.model.TransactionType;
import com.tracker.expense.model.User;
import com.tracker.expense.repository.CategoryRepository;
import com.tracker.expense.repository.PaymentMethodRepository;
import com.tracker.expense.repository.UserRepository;
import com.tracker.expense.security.JwtService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final CategoryRepository categoryRepository;
    private final PaymentMethodRepository paymentMethodRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        String normalizedEmail = request.getEmail().trim().toLowerCase();

        if (userRepository.existsByEmail(normalizedEmail)) {
            throw new BadRequestException("Email is already registered");
        }

        User user = User.builder()
                .email(normalizedEmail)
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .fullName(request.getFullName().trim())
                .currency(request.getCurrency() != null ? request.getCurrency().trim().toUpperCase() : "VND")
                .timezone(request.getTimezone() != null ? request.getTimezone().trim() : "Asia/Ho_Chi_Minh")
                .build();

        user = userRepository.save(user);

        // Seed default categories & payment methods for new user
        seedDefaultUserData(user.getId());

        String accessToken = jwtService.generateAccessToken(user.getId(), user.getEmail());
        String refreshToken = jwtService.generateRefreshToken(user.getId());

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .tokenType("Bearer")
                .expiresIn(jwtService.getAccessTokenExpirationMs())
                .user(UserResponse.fromEntity(user))
                .build();
    }

    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        String normalizedEmail = request.getEmail().trim().toLowerCase();

        User user = userRepository.findByEmail(normalizedEmail)
                .orElseThrow(() -> new BadCredentialsException("Invalid email or password"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new BadCredentialsException("Invalid email or password");
        }

        String accessToken = jwtService.generateAccessToken(user.getId(), user.getEmail());
        String refreshToken = jwtService.generateRefreshToken(user.getId());

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .tokenType("Bearer")
                .expiresIn(jwtService.getAccessTokenExpirationMs())
                .user(UserResponse.fromEntity(user))
                .build();
    }

    @Transactional(readOnly = true)
    public AuthResponse refreshToken(RefreshTokenRequest request) {
        String token = request.getRefreshToken();

        if (!jwtService.validateToken(token) || !jwtService.isRefreshToken(token)) {
            throw new UnauthorizedException("Invalid or expired refresh token");
        }

        UUID userId = jwtService.extractUserId(token);
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new UnauthorizedException("User not found"));

        String newAccessToken = jwtService.generateAccessToken(user.getId(), user.getEmail());
        String newRefreshToken = jwtService.generateRefreshToken(user.getId());

        return AuthResponse.builder()
                .accessToken(newAccessToken)
                .refreshToken(newRefreshToken)
                .tokenType("Bearer")
                .expiresIn(jwtService.getAccessTokenExpirationMs())
                .user(UserResponse.fromEntity(user))
                .build();
    }

    @Transactional(readOnly = true)
    public UserResponse getCurrentUser(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        return UserResponse.fromEntity(user);
    }

    @Transactional
    public UserResponse updateProfile(UUID userId, UpdateProfileRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        if (request.getFullName() != null && !request.getFullName().isBlank()) {
            user.setFullName(request.getFullName().trim());
        }
        if (request.getCurrency() != null && !request.getCurrency().isBlank()) {
            user.setCurrency(request.getCurrency().trim().toUpperCase());
        }
        if (request.getTimezone() != null && !request.getTimezone().isBlank()) {
            user.setTimezone(request.getTimezone().trim());
        }

        user = userRepository.save(user);
        return UserResponse.fromEntity(user);
    }

    private void seedDefaultUserData(UUID userId) {
        List<Category> defaultCategories = List.of(
                Category.builder().userId(userId).name("Ăn uống").type(TransactionType.EXPENSE).color("#FF5722").icon("restaurant").build(),
                Category.builder().userId(userId).name("Đi lại").type(TransactionType.EXPENSE).color("#2196F3").icon("directions_car").build(),
                Category.builder().userId(userId).name("Tiền nhà").type(TransactionType.EXPENSE).color("#9C27B0").icon("home").build(),
                Category.builder().userId(userId).name("Mua sắm").type(TransactionType.EXPENSE).color("#E91E63").icon("shopping_cart").build(),
                Category.builder().userId(userId).name("Hoá đơn & Tiện ích").type(TransactionType.EXPENSE).color("#FF9800").icon("receipt_long").build(),
                Category.builder().userId(userId).name("Giải trí").type(TransactionType.EXPENSE).color("#00BCD4").icon("sports_esports").build(),
                Category.builder().userId(userId).name("Y tế & Sức khoẻ").type(TransactionType.EXPENSE).color("#E53935").icon("medical_services").build(),
                Category.builder().userId(userId).name("Giáo dục").type(TransactionType.EXPENSE).color("#3F51B5").icon("school").build(),
                Category.builder().userId(userId).name("Lương").type(TransactionType.INCOME).color("#4CAF50").icon("payments").build(),
                Category.builder().userId(userId).name("Thưởng").type(TransactionType.INCOME).color("#009688").icon("card_giftcard").build(),
                Category.builder().userId(userId).name("Đầu tư").type(TransactionType.INCOME).color("#8BC34A").icon("trending_up").build(),
                Category.builder().userId(userId).name("Khác").type(TransactionType.INCOME).color("#607D8B").icon("savings").build()
        );
        categoryRepository.saveAll(defaultCategories);

        List<PaymentMethod> defaultPaymentMethods = List.of(
                PaymentMethod.builder().userId(userId).name("Tiền mặt").build(),
                PaymentMethod.builder().userId(userId).name("Thẻ VISA / MasterCard").build(),
                PaymentMethod.builder().userId(userId).name("Chuyển khoản").build(),
                PaymentMethod.builder().userId(userId).name("Ví MoMo").build()
        );
        paymentMethodRepository.saveAll(defaultPaymentMethods);

        log.debug("Seeded default categories and payment methods for user: {}", userId);
    }
}
