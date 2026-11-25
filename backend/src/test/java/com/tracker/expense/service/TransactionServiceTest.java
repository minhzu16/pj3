package com.tracker.expense.service;

import com.tracker.expense.common.exception.BadRequestException;
import com.tracker.expense.common.exception.ResourceNotFoundException;
import com.tracker.expense.dto.CreateTransactionRequest;
import com.tracker.expense.dto.TransactionWithAlertsResponse;
import com.tracker.expense.model.Budget;
import com.tracker.expense.model.Category;
import com.tracker.expense.model.Transaction;
import com.tracker.expense.model.TransactionType;
import com.tracker.expense.repository.BudgetRepository;
import com.tracker.expense.repository.CategoryRepository;
import com.tracker.expense.repository.PaymentMethodRepository;
import com.tracker.expense.repository.TransactionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TransactionServiceTest {

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
    private final UUID transactionId = UUID.randomUUID();

    private Category expenseCategory;
    private Category incomeCategory;
    private Transaction sampleTransaction;

    @BeforeEach
    void setUp() {
        expenseCategory = Category.builder()
                .id(categoryId)
                .userId(userAId)
                .name("Ăn uống")
                .type(TransactionType.EXPENSE)
                .build();

        incomeCategory = Category.builder()
                .id(categoryId)
                .userId(userAId)
                .name("Lương")
                .type(TransactionType.INCOME)
                .build();

        sampleTransaction = Transaction.builder()
                .id(transactionId)
                .userId(userAId)
                .type(TransactionType.EXPENSE)
                .amount(new BigDecimal("150000.00"))
                .txnDate(LocalDate.of(2026, 10, 1))
                .categoryId(categoryId)
                .createdAt(Instant.now())
                .updatedAt(Instant.now())
                .build();
    }

    @Test
    void createTransaction_categoryTypeMismatch_shouldThrowBadRequestException() {
        CreateTransactionRequest request = CreateTransactionRequest.builder()
                .type(TransactionType.EXPENSE)
                .amount(new BigDecimal("50000.00"))
                .txnDate(LocalDate.of(2026, 10, 1))
                .categoryId(categoryId)
                .build();

        when(categoryRepository.findByIdAndUserId(categoryId, userAId)).thenReturn(Optional.of(incomeCategory));

        assertThrows(BadRequestException.class, () -> transactionService.createTransaction(userAId, request));
    }

    @Test
    void createTransaction_usingAnotherUsersCategory_shouldThrowResourceNotFound_IDORProtection() {
        CreateTransactionRequest request = CreateTransactionRequest.builder()
                .type(TransactionType.EXPENSE)
                .amount(new BigDecimal("50000.00"))
                .txnDate(LocalDate.of(2026, 10, 1))
                .categoryId(categoryId)
                .build();

        // User B tries to use User A's category
        when(categoryRepository.findByIdAndUserId(categoryId, userBId)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> transactionService.createTransaction(userBId, request));
    }

    @Test
    void createTransaction_withBudgetWarning_shouldReturnBudgetAlert() {
        CreateTransactionRequest request = CreateTransactionRequest.builder()
                .type(TransactionType.EXPENSE)
                .amount(new BigDecimal("850000.00"))
                .txnDate(LocalDate.of(2026, 10, 15))
                .categoryId(categoryId)
                .build();

        when(categoryRepository.findByIdAndUserId(categoryId, userAId)).thenReturn(Optional.of(expenseCategory));
        when(transactionRepository.save(any(Transaction.class))).thenReturn(sampleTransaction);

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
        when(transactionRepository.sumExpenseForCategoryBetween(userAId, categoryId, monthStart, nextMonthStart))
                .thenReturn(new BigDecimal("850000.00")); // 85% spent

        when(budgetRepository.findByUserIdAndCategoryIdIsNullAndMonth(userAId, monthStart))
                .thenReturn(Optional.empty());

        TransactionWithAlertsResponse response = transactionService.createTransaction(userAId, request);

        assertNotNull(response);
        assertFalse(response.getBudgetAlerts().isEmpty());
        assertEquals("warning", response.getBudgetAlerts().getFirst().getStatus());
        assertEquals(new BigDecimal("85.0"), response.getBudgetAlerts().getFirst().getPercent());
    }

    @Test
    void createTransaction_withBudgetExceeded_shouldReturnExceededAlert() {
        CreateTransactionRequest request = CreateTransactionRequest.builder()
                .type(TransactionType.EXPENSE)
                .amount(new BigDecimal("1200000.00"))
                .txnDate(LocalDate.of(2026, 10, 15))
                .categoryId(categoryId)
                .build();

        when(categoryRepository.findByIdAndUserId(categoryId, userAId)).thenReturn(Optional.of(expenseCategory));
        when(transactionRepository.save(any(Transaction.class))).thenReturn(sampleTransaction);

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
        when(transactionRepository.sumExpenseForCategoryBetween(userAId, categoryId, monthStart, nextMonthStart))
                .thenReturn(new BigDecimal("1200000.00")); // 120% spent

        when(budgetRepository.findByUserIdAndCategoryIdIsNullAndMonth(userAId, monthStart))
                .thenReturn(Optional.empty());

        TransactionWithAlertsResponse response = transactionService.createTransaction(userAId, request);

        assertNotNull(response);
        assertFalse(response.getBudgetAlerts().isEmpty());
        assertEquals("exceeded", response.getBudgetAlerts().getFirst().getStatus());
    }

    @Test
    void getTransactionById_belongingToAnotherUser_shouldThrowResourceNotFound_IDORProtection() {
        when(transactionRepository.findByIdAndUserIdAndDeletedAtIsNull(transactionId, userBId))
                .thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> transactionService.getTransactionById(userBId, transactionId));
    }

    @Test
    void deleteTransaction_shouldSetDeletedAtSoftDelete() {
        when(transactionRepository.findByIdAndUserIdAndDeletedAtIsNull(transactionId, userAId))
                .thenReturn(Optional.of(sampleTransaction));

        transactionService.deleteTransaction(userAId, transactionId);

        assertNotNull(sampleTransaction.getDeletedAt());
        verify(transactionRepository).save(sampleTransaction);
    }
}
