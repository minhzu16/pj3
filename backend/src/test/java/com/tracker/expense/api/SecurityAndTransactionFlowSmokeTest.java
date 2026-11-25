package com.tracker.expense.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tracker.expense.config.ClockConfig;
import com.tracker.expense.config.SecurityConfig;
import com.tracker.expense.dto.CreateTransactionRequest;
import com.tracker.expense.dto.PagedTransactionResponse;
import com.tracker.expense.dto.TransactionTotals;
import com.tracker.expense.dto.TransactionWithAlertsResponse;
import com.tracker.expense.dto.budget.BudgetResponse;
import com.tracker.expense.model.TransactionType;
import com.tracker.expense.security.CustomUserDetailsService;
import com.tracker.expense.security.JwtAuthenticationEntryPoint;
import com.tracker.expense.security.JwtAuthenticationFilter;
import com.tracker.expense.security.JwtService;
import com.tracker.expense.security.UserPrincipal;
import com.tracker.expense.service.BudgetService;
import com.tracker.expense.service.CsvExportService;
import com.tracker.expense.service.SplitTransactionService;
import com.tracker.expense.service.TransactionService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = {HealthController.class, TransactionController.class, BudgetController.class})
@Import({SecurityConfig.class, JwtAuthenticationEntryPoint.class, JwtAuthenticationFilter.class, ClockConfig.class})
class SecurityAndTransactionFlowSmokeTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private TransactionService transactionService;

    @MockBean
    private SplitTransactionService splitTransactionService;

    @MockBean
    private CsvExportService csvExportService;

    @MockBean
    private BudgetService budgetService;

    @MockBean
    private JwtService jwtService;

    @MockBean
    private CustomUserDetailsService userDetailsService;

    @Test
    void healthEndpoint_shouldIncludeSecurityHeaders() throws Exception {
        mockMvc.perform(get("/api/v1/health"))
                .andExpect(status().isOk())
                .andExpect(header().string("X-Content-Type-Options", "nosniff"))
                .andExpect(header().string("X-Frame-Options", "DENY"))
                .andExpect(header().string("X-XSS-Protection", "1; mode=block"))
                .andExpect(header().string("Content-Security-Policy", "default-src 'self'; frame-ancestors 'none'; object-src 'none'"));
    }

    @Test
    void corsPreflight_shouldAllowConfiguredOriginAndRejectUnknownOrigin() throws Exception {
        mockMvc.perform(options("/api/v1/transactions")
                        .header("Origin", "http://localhost:3000")
                        .header("Access-Control-Request-Method", "GET"))
                .andExpect(status().isOk())
                .andExpect(header().string("Access-Control-Allow-Origin", "http://localhost:3000"));

        mockMvc.perform(options("/api/v1/transactions")
                        .header("Origin", "https://evil.example.com")
                        .header("Access-Control-Request-Method", "GET"))
                .andExpect(status().isForbidden());
    }

    @Test
    void protectedEndpoints_withoutAuth_shouldReturn401() throws Exception {
        mockMvc.perform(get("/api/v1/transactions"))
                .andExpect(status().isUnauthorized());

        mockMvc.perform(get("/api/v1/budgets"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void authenticatedUser_transactionAndBudgetFlow_shouldSucceed() throws Exception {
        UUID userId = UUID.randomUUID();
        UUID categoryId = UUID.randomUUID();
        UserPrincipal principal = new UserPrincipal(
                userId,
                "smoke@example.com",
                "hashed",
                List.of(new SimpleGrantedAuthority("ROLE_USER"))
        );

        CreateTransactionRequest request = CreateTransactionRequest.builder()
                .type(TransactionType.EXPENSE)
                .amount(new BigDecimal("150000"))
                .txnDate(LocalDate.of(2026, 11, 25))
                .categoryId(categoryId)
                .note("Lunch")
                .build();

        TransactionWithAlertsResponse created = TransactionWithAlertsResponse.builder()
                .budgetAlerts(List.of())
                .build();

        when(transactionService.createTransaction(eq(userId), any(CreateTransactionRequest.class)))
                .thenReturn(created);
        when(transactionService.getTransactions(eq(userId), any()))
                .thenReturn(PagedTransactionResponse.builder()
                        .items(List.of())
                        .total(0)
                        .page(1)
                        .pageSize(20)
                        .totals(TransactionTotals.builder()
                                .income(BigDecimal.ZERO)
                                .expense(new BigDecimal("150000"))
                                .build())
                        .build());
        when(budgetService.getBudgets(eq(userId), any(YearMonth.class)))
                .thenReturn(List.of(BudgetResponse.builder()
                        .id(UUID.randomUUID())
                        .month(LocalDate.of(2026, 11, 1))
                        .amountLimit(new BigDecimal("5000000"))
                        .spent(new BigDecimal("150000"))
                        .build()));

        mockMvc.perform(post("/api/v1/transactions")
                        .with(user(principal))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated());

        mockMvc.perform(get("/api/v1/transactions").with(user(principal)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totals.expense").value(150000));

        mockMvc.perform(get("/api/v1/budgets")
                        .param("month", "2026-11")
                        .with(user(principal)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].month").value("2026-11-01"))
                .andExpect(jsonPath("$[0].spent").value(150000));
    }
}
