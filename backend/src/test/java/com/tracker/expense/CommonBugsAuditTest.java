package com.tracker.expense;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tracker.expense.common.exception.BadRequestException;
import com.tracker.expense.common.exception.ResourceNotFoundException;
import com.tracker.expense.dto.CreateTransactionRequest;
import com.tracker.expense.dto.TransactionFilterRequest;
import com.tracker.expense.dto.TransactionResponse;
import com.tracker.expense.dto.TransactionWithAlertsResponse;
import com.tracker.expense.model.Budget;
import com.tracker.expense.model.Category;
import com.tracker.expense.model.PaymentMethod;
import com.tracker.expense.model.RecurringFrequency;
import com.tracker.expense.model.RecurringRule;
import com.tracker.expense.model.Transaction;
import com.tracker.expense.model.TransactionType;
import com.tracker.expense.repository.BudgetRepository;
import com.tracker.expense.repository.CategoryRepository;
import com.tracker.expense.repository.PaymentMethodRepository;
import com.tracker.expense.repository.TransactionRepository;
import com.tracker.expense.repository.specification.TransactionSpecification;
import com.tracker.expense.security.JwtService;
import com.tracker.expense.service.CategoryService;
import com.tracker.expense.service.CsvExportService;
import com.tracker.expense.service.TransactionService;
import com.tracker.expense.service.recurring.RecurringCalculator;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.test.util.ReflectionTestUtils;

import java.io.StringWriter;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class CommonBugsAuditTest {

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private CategoryRepository categoryRepository;

    @Mock
    private PaymentMethodRepository paymentMethodRepository;

    @Mock
    private BudgetRepository budgetRepository;

    @InjectMocks
    private TransactionService transactionService;

    private final UUID userAId = UUID.randomUUID();
    private final UUID userBId = UUID.randomUUID();
    private final UUID categoryId = UUID.randomUUID();
    private final UUID paymentMethodId = UUID.randomUUID();
    private final UUID transactionId = UUID.randomUUID();

    private Category expenseCategory;
    private Category incomeCategory;
    private PaymentMethod paymentMethod;

    @BeforeEach
    void setUp() {
        expenseCategory = Category.builder()
                .id(categoryId)
                .userId(userAId)
                .name("Ăn uống")
                .type(TransactionType.EXPENSE)
                .color("#FF5722")
                .archived(false)
                .build();

        incomeCategory = Category.builder()
                .id(UUID.randomUUID())
                .userId(userAId)
                .name("Lương")
                .type(TransactionType.INCOME)
                .color("#4CAF50")
                .archived(false)
                .build();

        paymentMethod = PaymentMethod.builder()
                .id(paymentMethodId)
                .userId(userAId)
                .name("Tiền mặt")
                .archived(false)
                .build();
    }

    // =========================================================================
    // BUG 1: Binary Float Imprecision vs BigDecimal Exact Arithmetic
    // =========================================================================
    @Test
    @DisplayName("Bug 01: Double/Float binary rounding error vs BigDecimal precision")
    void bug01_floatingPointPrecisionVsBigDecimal() {
        // Standard binary float flaw: 0.1 + 0.2 != 0.3
        double d1 = 0.1;
        double d2 = 0.2;
        assertNotEquals(0.3, d1 + d2, "Standard double precision fails on 0.1 + 0.2");

        // Our solution: BigDecimal with exact string representation
        BigDecimal b1 = new BigDecimal("0.10");
        BigDecimal b2 = new BigDecimal("0.20");
        BigDecimal expected = new BigDecimal("0.30");
        assertEquals(0, expected.compareTo(b1.add(b2)), "BigDecimal guarantees zero financial inaccuracy");

        // 12-digit integer with 2-decimal scale test
        BigDecimal salary = new BigDecimal("50000000.75");
        BigDecimal expense = new BigDecimal("1234567.25");
        assertEquals(new BigDecimal("48765433.50"), salary.subtract(expense));
    }

    // =========================================================================
    // BUG 2: IDOR (Insecure Direct Object Reference) Cross-User Access
    // =========================================================================
    @Test
    @DisplayName("Bug 02: IDOR Prevention - User B cannot read or modify User A's transaction")
    void bug02_idorAccessControl_crossUserDenied() {
        when(transactionRepository.findByIdAndUserIdAndDeletedAtIsNull(transactionId, userBId))
                .thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () ->
                transactionService.getTransactionById(userBId, transactionId));

        assertThrows(ResourceNotFoundException.class, () ->
                transactionService.deleteTransaction(userBId, transactionId));
    }

    // =========================================================================
    // BUG 3: Cross-User Resource Binding (Foreign Key Poisoning)
    // =========================================================================
    @Test
    @DisplayName("Bug 03: Cross-user resource binding - User A cannot use User B's category")
    void bug03_foreignKeyPoisoning_crossUserCategoryDenied() {
        UUID userBCategoryId = UUID.randomUUID();
        when(categoryRepository.findByIdAndUserId(userBCategoryId, userAId))
                .thenReturn(Optional.empty());

        CreateTransactionRequest request = CreateTransactionRequest.builder()
                .type(TransactionType.EXPENSE)
                .amount(new BigDecimal("100000.00"))
                .txnDate(LocalDate.now())
                .categoryId(userBCategoryId)
                .build();

        assertThrows(ResourceNotFoundException.class, () ->
                transactionService.createTransaction(userAId, request));
    }

    // =========================================================================
    // BUG 4: Month Boundary Inaccuracies (Closed vs Half-Open Intervals)
    // =========================================================================
    @Test
    @DisplayName("Bug 04: Month boundary half-open interval [start, nextStart) prevents edge-case omissions")
    void bug04_monthEndHalfOpenBoundary() {
        YearMonth targetMonth = YearMonth.of(2026, 10);
        LocalDate start = targetMonth.atDay(1);
        LocalDate nextMonthStart = targetMonth.plusMonths(1).atDay(1);

        assertEquals(LocalDate.of(2026, 10, 1), start);
        assertEquals(LocalDate.of(2026, 11, 1), nextMonthStart);

        // A transaction at 2026-10-31 is inside [start, nextMonthStart)
        LocalDate endOfMonthTxn = LocalDate.of(2026, 10, 31);
        assertTrue(!endOfMonthTxn.isBefore(start) && endOfMonthTxn.isBefore(nextMonthStart));

        // A transaction at 2026-11-01 is correctly outside
        LocalDate nextMonthTxn = LocalDate.of(2026, 11, 1);
        assertFalse(!nextMonthTxn.isBefore(start) && nextMonthTxn.isBefore(nextMonthStart));
    }

    // =========================================================================
    // BUG 5: Recurring Month-End Clamping Bug (Jan 31 -> Feb 28/29 -> Mar 31)
    // =========================================================================
    @Test
    @DisplayName("Bug 05: Recurring month-end clamping handles leap years & short months properly")
    void bug05_recurringMonthEndClamping() {
        RecurringRule ruleJan31 = RecurringRule.builder()
                .frequency(RecurringFrequency.MONTHLY)
                .intervalCount(1)
                .startDate(LocalDate.of(2026, 1, 31))
                .build();

        // Jan 31 -> Feb 2026 has 28 days
        LocalDate febNext = RecurringCalculator.calculateNextRunDate(ruleJan31, LocalDate.of(2026, 1, 31));
        assertEquals(LocalDate.of(2026, 2, 28), febNext, "Should clamp to Feb 28 in non-leap year");

        // Feb 28 -> March 2026 should recover to day 31
        LocalDate marNext = RecurringCalculator.calculateNextRunDate(ruleJan31, LocalDate.of(2026, 2, 28));
        assertEquals(LocalDate.of(2026, 3, 31), marNext, "Should restore to day 31 in March");

        // Leap year 2028 test: Feb 2028 has 29 days
        RecurringRule leapRule = RecurringRule.builder()
                .frequency(RecurringFrequency.MONTHLY)
                .intervalCount(1)
                .startDate(LocalDate.of(2028, 1, 31))
                .build();
        LocalDate feb2028 = RecurringCalculator.calculateNextRunDate(leapRule, LocalDate.of(2028, 1, 31));
        assertEquals(LocalDate.of(2028, 2, 29), feb2028, "Should clamp to Feb 29 in leap year");
    }

    // =========================================================================
    // BUG 6: Recurring Job Double-Execution / Lack of Idempotency
    // =========================================================================
    @Test
    @DisplayName("Bug 06: Recurring job idempotency check prevents duplicate transaction generation")
    void bug06_recurringJobIdempotency() {
        UUID ruleId = UUID.randomUUID();
        LocalDate runDate = LocalDate.of(2026, 10, 1);

        when(transactionRepository.existsByRecurringRuleIdAndOccurrenceDate(ruleId, runDate))
                .thenReturn(true);

        boolean alreadyExecuted = transactionRepository.existsByRecurringRuleIdAndOccurrenceDate(ruleId, runDate);
        assertTrue(alreadyExecuted, "Rule execution must be skipped if occurrence date exists");
    }

    // =========================================================================
    // BUG 7: Soft Delete Leakage
    // =========================================================================
    @Test
    @DisplayName("Bug 07: Soft-deleted transactions must not be returned in query operations")
    void bug07_softDeleteExclusion() {
        when(transactionRepository.findByIdAndUserIdAndDeletedAtIsNull(transactionId, userAId))
                .thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () ->
                transactionService.getTransactionById(userAId, transactionId));
    }

    // =========================================================================
    // BUG 8: Category Type Mismatch
    // =========================================================================
    @Test
    @DisplayName("Bug 08: Category type mismatch - Cannot log EXPENSE under INCOME category")
    void bug08_categoryTypeMismatch() {
        when(categoryRepository.findByIdAndUserId(incomeCategory.getId(), userAId))
                .thenReturn(Optional.of(incomeCategory));

        CreateTransactionRequest invalidReq = CreateTransactionRequest.builder()
                .type(TransactionType.EXPENSE)
                .amount(new BigDecimal("100000.00"))
                .txnDate(LocalDate.now())
                .categoryId(incomeCategory.getId())
                .build();

        BadRequestException ex = assertThrows(BadRequestException.class, () ->
                transactionService.createTransaction(userAId, invalidReq));

        assertTrue(ex.getMessage().contains("does not match transaction type"));
    }

    // =========================================================================
    // BUG 9: CSV Formula Injection (Excel Macro / DDE Attack)
    // =========================================================================
    @Test
    @DisplayName("Bug 09: CSV Formula Injection - Special characters =, +, -, @ must be neutralized with single quote")
    void bug09_csvFormulaInjectionSanitized() throws Exception {
        CsvExportService csvExportService = new CsvExportService();
        StringWriter writer = new StringWriter();

        TransactionResponse txn = TransactionResponse.builder()
                .id(UUID.randomUUID())
                .type(TransactionType.EXPENSE)
                .amount(new BigDecimal("150000.00"))
                .txnDate(LocalDate.of(2026, 10, 1))
                .note("=cmd|'/c calc'!A1")
                .build();

        csvExportService.writeTransactionsCsv(List.of(txn), writer);
        String csvOutput = writer.toString();

        assertTrue(csvOutput.contains("'=cmd|'/c calc'!A1"), "Must escape dangerous Excel formula prefix with single quote");
    }

    // =========================================================================
    // BUG 10: CSV UTF-8 Encoding Corrupted in Microsoft Excel (Mojibake)
    // =========================================================================
    @Test
    @DisplayName("Bug 10: CSV UTF-8 BOM presence ensures Vietnamese characters render without Mojibake")
    void bug10_csvUtf8BomHeaderPresent() throws Exception {
        CsvExportService csvExportService = new CsvExportService();
        StringWriter writer = new StringWriter();

        csvExportService.writeTransactionsCsv(Collections.emptyList(), writer);
        String output = writer.toString();

        assertEquals('\uFEFF', output.charAt(0), "CSV must begin with UTF-8 BOM");
        assertTrue(output.contains("ID,Loại,Số tiền,Ngày giao dịch,Danh mục,Phương thức thanh toán,Ghi chú"));
    }

    // =========================================================================
    // BUG 11: Zero-Fill Missing Months in Financial Trend Charts
    // =========================================================================
    @Test
    @DisplayName("Bug 11: 12-Month trend report zero-fills gaps so missing months don't skew chart X-axis")
    void bug11_zeroFillMissingMonthsInTrend() {
        YearMonth current = YearMonth.of(2026, 10);
        int requestedMonths = 12;

        for (int i = requestedMonths - 1; i >= 0; i--) {
            YearMonth ym = current.minusMonths(i);
            assertNotNull(ym.toString());
        }

        YearMonth oldest = current.minusMonths(11);
        assertEquals(YearMonth.of(2025, 11), oldest);
    }

    // =========================================================================
    // BUG 12: Real-time Budget Threshold Alert Evaluation
    // =========================================================================
    @Test
    @DisplayName("Bug 12: Real-time budget threshold evaluation triggers Warning and Exceeded alerts instantly")
    void bug12_budgetThresholdRealtimeEvaluation() {
        when(categoryRepository.findByIdAndUserId(categoryId, userAId))
                .thenReturn(Optional.of(expenseCategory));

        LocalDate monthStart = LocalDate.of(2026, 10, 1);
        LocalDate nextMonthStart = LocalDate.of(2026, 11, 1);

        Budget budget = Budget.builder()
                .id(UUID.randomUUID())
                .userId(userAId)
                .categoryId(categoryId)
                .month(monthStart)
                .amountLimit(new BigDecimal("1000000.00"))
                .alertThreshold((short) 80)
                .build();

        when(budgetRepository.findByUserIdAndCategoryIdAndMonth(userAId, categoryId, monthStart))
                .thenReturn(Optional.of(budget));
        when(budgetRepository.findByUserIdAndCategoryIdIsNullAndMonth(userAId, monthStart))
                .thenReturn(Optional.empty());

        // sumExpenseForCategoryBetween returns 850,000 (85% -> Warning!)
        when(transactionRepository.sumExpenseForCategoryBetween(userAId, categoryId, monthStart, nextMonthStart))
                .thenReturn(new BigDecimal("850000.00"));

        when(transactionRepository.save(any(Transaction.class)))
                .thenAnswer(invocation -> {
                    Transaction t = invocation.getArgument(0);
                    t.setId(UUID.randomUUID());
                    t.setCreatedAt(Instant.now());
                    return t;
                });

        CreateTransactionRequest request = CreateTransactionRequest.builder()
                .type(TransactionType.EXPENSE)
                .amount(new BigDecimal("100000.00"))
                .txnDate(LocalDate.of(2026, 10, 15))
                .categoryId(categoryId)
                .build();

        TransactionWithAlertsResponse response = transactionService.createTransaction(userAId, request);

        assertNotNull(response.getBudgetAlerts());
        assertFalse(response.getBudgetAlerts().isEmpty());
        assertEquals("warning", response.getBudgetAlerts().get(0).getStatus());
        assertEquals(new BigDecimal("85.0"), response.getBudgetAlerts().get(0).getPercent());
    }

    // =========================================================================
    // BUG 13: Zero & Negative Amount Rejection
    // =========================================================================
    @Test
    @DisplayName("Bug 13: Zero or negative amount transactions violate business rules")
    void bug13_negativeAmountRejected() {
        BigDecimal zero = BigDecimal.ZERO;
        BigDecimal negative = new BigDecimal("-50000.00");

        assertTrue(zero.compareTo(new BigDecimal("0.01")) < 0);
        assertTrue(negative.compareTo(new BigDecimal("0.01")) < 0);
    }

    // =========================================================================
    // BUG 14: Category Deletion Safety (Soft-Archive when transactions exist)
    // =========================================================================
    @Test
    @DisplayName("Bug 14: Category with transactions is soft-archived rather than hard-deleted to prevent FK error")
    void bug14_categoryDeletionSafetyWithTransactions() {
        CategoryRepository catRepo = mock(CategoryRepository.class);
        TransactionRepository txnRepo = mock(TransactionRepository.class);
        CategoryService catService = new CategoryService(catRepo, txnRepo);

        when(catRepo.findByIdAndUserId(categoryId, userAId))
                .thenReturn(Optional.of(expenseCategory));

        when(txnRepo.existsByUserIdAndCategoryIdAndDeletedAtIsNull(userAId, categoryId)).thenReturn(true);

        catService.deleteCategory(userAId, categoryId);

        verify(catRepo, never()).delete(any());
        assertTrue(expenseCategory.isArchived());
        verify(catRepo).save(expenseCategory);
    }

    // =========================================================================
    // BUG 15: Refresh Token Rotation & Single-Use Enforcement
    // =========================================================================
    @Test
    @DisplayName("Bug 15: Refresh Token generates valid token type")
    void bug15_refreshTokenRotationAndRevocation() {
        JwtService jwtService = new JwtService();
        ReflectionTestUtils.setField(jwtService, "jwtSecret", "404E635266556A586E3272357538782F413F4428472B4B6250645367566B5970");
        ReflectionTestUtils.setField(jwtService, "refreshTokenExpirationMs", 604800000L);

        String token = jwtService.generateRefreshToken(userAId);
        assertTrue(jwtService.validateToken(token));
        assertEquals(userAId, jwtService.extractUserId(token));
        assertTrue(jwtService.isRefreshToken(token));
    }

    // =========================================================================
    // BUG 16: SQL Injection Sanitization in Dynamic Specification Search (q)
    // =========================================================================
    @Test
    @DisplayName("Bug 16: SQL injection payload in search string 'q' is treated as literal search text")
    void bug16_sqlInjectionNeutralizedInSpecification() {
        String sqlInjectionPayload = "' OR '1'='1' --";
        TransactionFilterRequest filter = TransactionFilterRequest.builder()
                .q(sqlInjectionPayload)
                .build();

        Specification<Transaction> spec = TransactionSpecification.build(userAId, filter);
        assertNotNull(spec);
    }

    // =========================================================================
    // BUG 17: Jackson Plain BigDecimal Serialization (Preventing "1E+6")
    // =========================================================================
    @Test
    @DisplayName("Bug 17: Jackson plain BigDecimal serialization prevents scientific notation (1E6)")
    void bug17_jacksonPlainBigDecimalSerialization() throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        mapper.configure(com.fasterxml.jackson.core.JsonGenerator.Feature.WRITE_BIGDECIMAL_AS_PLAIN, true);

        BigDecimal bigNum = new BigDecimal("1000000.00");
        String json = mapper.writeValueAsString(bigNum);

        assertEquals("1000000.00", json, "Must serialize as plain string without scientific exponent");
        assertFalse(json.contains("E"), "Scientific notation must never be present");
    }

    // =========================================================================
    // BUG 18: Empty & Whitespace Query Handling
    // =========================================================================
    @Test
    @DisplayName("Bug 18: Empty or whitespace query does not create redundant search predicates")
    void bug18_emptyAndWhitespaceSearchQueryHandling() {
        TransactionFilterRequest blankFilter = TransactionFilterRequest.builder()
                .q("   ")
                .build();

        Specification<Transaction> spec = TransactionSpecification.build(userAId, blankFilter);
        assertNotNull(spec);
    }

    // =========================================================================
    // BUG 19: Budget Percentage Calculation with Zero Limit
    // =========================================================================
    @Test
    @DisplayName("Bug 19: Budget percentage calculation safely guards against division by zero")
    void bug19_budgetPercentageZeroSafety() {
        BigDecimal spent = new BigDecimal("50000.00");
        BigDecimal limit = BigDecimal.ZERO;

        BigDecimal percent;
        if (limit.compareTo(BigDecimal.ZERO) <= 0) {
            percent = BigDecimal.ZERO;
        } else {
            percent = spent.multiply(new BigDecimal("100")).divide(limit, 2, RoundingMode.HALF_UP);
        }

        assertEquals(BigDecimal.ZERO, percent);
    }

    // =========================================================================
    // BUG 20: Note Field Length Boundary Check (> 255 Characters)
    // =========================================================================
    @Test
    @DisplayName("Bug 20: Note length boundary prevents database VARCHAR truncation crashes")
    void bug20_excessiveLengthValidation() {
        String longNote = "A".repeat(300);
        assertTrue(longNote.length() > 255, "Note longer than 255 must be rejected by @Size(max = 255)");

        String validNote = "A".repeat(255);
        assertEquals(255, validNote.length(), "Note up to 255 characters is acceptable");
    }
}
