package com.tracker.expense.service;

import com.tracker.expense.common.exception.BadRequestException;
import com.tracker.expense.common.exception.ResourceNotFoundException;
import com.tracker.expense.dto.CreateSplitTransactionRequest;
import com.tracker.expense.dto.CreateTransactionRequest;
import com.tracker.expense.dto.PaymentMethodResponse;
import com.tracker.expense.dto.SplitItemRequest;
import com.tracker.expense.dto.SplitTransactionResponse;
import com.tracker.expense.dto.TransactionResponse;
import com.tracker.expense.dto.TransactionWithAlertsResponse;
import com.tracker.expense.model.Category;
import com.tracker.expense.model.PaymentMethod;
import com.tracker.expense.model.TransactionType;
import com.tracker.expense.repository.CategoryRepository;
import com.tracker.expense.repository.PaymentMethodRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@DisplayName("SplitTransactionService - Real-world Multi-Category Split & Sum Invariant Tests (YNAB/Monarch Model)")
class SplitTransactionTest {

    @Mock
    private TransactionService transactionService;

    @Mock
    private CategoryRepository categoryRepository;

    @Mock
    private PaymentMethodRepository paymentMethodRepository;

    @InjectMocks
    private SplitTransactionService splitTransactionService;

    private final UUID userId = UUID.randomUUID();
    private final UUID groceryCategoryId = UUID.randomUUID();
    private final UUID householdCategoryId = UUID.randomUUID();
    private final UUID personalCareCategoryId = UUID.randomUUID();
    private final UUID salaryCategoryId = UUID.randomUUID();
    private final UUID paymentMethodId = UUID.randomUUID();

    private Category groceryCategory;
    private Category householdCategory;
    private Category personalCareCategory;
    private Category salaryCategory;
    private PaymentMethod paymentMethod;

    @BeforeEach
    void setUp() {
        groceryCategory = Category.builder()
                .id(groceryCategoryId)
                .userId(userId)
                .name("Groceries")
                .type(TransactionType.EXPENSE)
                .build();

        householdCategory = Category.builder()
                .id(householdCategoryId)
                .userId(userId)
                .name("Household")
                .type(TransactionType.EXPENSE)
                .build();

        personalCareCategory = Category.builder()
                .id(personalCareCategoryId)
                .userId(userId)
                .name("Personal Care")
                .type(TransactionType.EXPENSE)
                .build();

        salaryCategory = Category.builder()
                .id(salaryCategoryId)
                .userId(userId)
                .name("Salary")
                .type(TransactionType.INCOME)
                .build();

        paymentMethod = PaymentMethod.builder()
                .id(paymentMethodId)
                .userId(userId)
                .name("Credit Card")
                .build();
    }

    @Test
    @DisplayName("Should successfully create split transactions when BigDecimal sum invariant exactly matches totalAmount")
    void createSplitTransaction_Success_WhenSumInvariantMatches() {
        // Total: 110.00 split into: 70.00 + 25.00 + 15.00 = 110.00
        BigDecimal totalAmount = new BigDecimal("110.00");
        List<SplitItemRequest> splits = List.of(
                SplitItemRequest.builder().categoryId(groceryCategoryId).amount(new BigDecimal("70.00")).note("Weekly groceries").build(),
                SplitItemRequest.builder().categoryId(householdCategoryId).amount(new BigDecimal("25.00")).note("Cleaning supplies").build(),
                SplitItemRequest.builder().categoryId(personalCareCategoryId).amount(new BigDecimal("15.00")).note("Shampoo").build()
        );

        CreateSplitTransactionRequest request = CreateSplitTransactionRequest.builder()
                .type(TransactionType.EXPENSE)
                .totalAmount(totalAmount)
                .txnDate(LocalDate.now())
                .paymentMethodId(paymentMethodId)
                .note("Supermarket mega store haul")
                .splits(splits)
                .build();

        when(paymentMethodRepository.findByIdAndUserId(paymentMethodId, userId)).thenReturn(Optional.of(paymentMethod));
        when(categoryRepository.findByIdAndUserId(groceryCategoryId, userId)).thenReturn(Optional.of(groceryCategory));
        when(categoryRepository.findByIdAndUserId(householdCategoryId, userId)).thenReturn(Optional.of(householdCategory));
        when(categoryRepository.findByIdAndUserId(personalCareCategoryId, userId)).thenReturn(Optional.of(personalCareCategory));

        when(transactionService.createTransaction(eq(userId), any(CreateTransactionRequest.class)))
                .thenAnswer(invocation -> {
                    CreateTransactionRequest req = invocation.getArgument(1);
                    return TransactionWithAlertsResponse.builder()
                            .transaction(TransactionResponse.builder()
                                    .id(UUID.randomUUID())
                                    .amount(req.getAmount())
                                    .type(req.getType())
                                    .txnDate(req.getTxnDate())
                                    .note(req.getNote())
                                    .build())
                            .budgetAlerts(List.of())
                            .build();
                });

        SplitTransactionResponse response = splitTransactionService.createSplitTransaction(userId, request);

        assertNotNull(response);
        assertNotNull(response.getSplitGroupId());
        assertEquals(TransactionType.EXPENSE, response.getType());
        assertEquals(0, totalAmount.compareTo(response.getTotalAmount()));
        assertEquals(3, response.getSplitCount());
        assertEquals(3, response.getSplitTransactions().size());
        assertEquals("Supermarket mega store haul", response.getMainNote());

        verify(transactionService, times(3)).createTransaction(eq(userId), any(CreateTransactionRequest.class));
    }

    @Test
    @DisplayName("Should throw BadRequestException (400) when sum of splits does not equal total amount (Sum Invariant violated)")
    void createSplitTransaction_ThrowsBadRequest_WhenSumInvariantViolated() {
        // Total expected 100.00 but splits sum to 95.00 (70.00 + 25.00)
        BigDecimal totalAmount = new BigDecimal("100.00");
        List<SplitItemRequest> splits = List.of(
                SplitItemRequest.builder().categoryId(groceryCategoryId).amount(new BigDecimal("70.00")).build(),
                SplitItemRequest.builder().categoryId(householdCategoryId).amount(new BigDecimal("25.00")).build()
        );

        CreateSplitTransactionRequest request = CreateSplitTransactionRequest.builder()
                .type(TransactionType.EXPENSE)
                .totalAmount(totalAmount)
                .txnDate(LocalDate.now())
                .splits(splits)
                .build();

        BadRequestException ex = assertThrows(BadRequestException.class,
                () -> splitTransactionService.createSplitTransaction(userId, request));

        assertTrue(ex.getMessage().contains("does not equal total transaction amount"));
        verify(transactionService, never()).createTransaction(any(), any());
    }

    @Test
    @DisplayName("Should throw BadRequestException when splits count is less than 2")
    void createSplitTransaction_ThrowsBadRequest_WhenFewerThanTwoSplits() {
        CreateSplitTransactionRequest request = CreateSplitTransactionRequest.builder()
                .type(TransactionType.EXPENSE)
                .totalAmount(new BigDecimal("50.00"))
                .txnDate(LocalDate.now())
                .splits(List.of(
                        SplitItemRequest.builder().categoryId(groceryCategoryId).amount(new BigDecimal("50.00")).build()
                ))
                .build();

        BadRequestException ex = assertThrows(BadRequestException.class,
                () -> splitTransactionService.createSplitTransaction(userId, request));

        assertTrue(ex.getMessage().contains("at least 2 split items"));
        verify(transactionService, never()).createTransaction(any(), any());
    }

    @Test
    @DisplayName("Should throw BadRequestException when any split item has non-positive amount")
    void createSplitTransaction_ThrowsBadRequest_WhenSplitAmountZeroOrNegative() {
        List<SplitItemRequest> splits = List.of(
                SplitItemRequest.builder().categoryId(groceryCategoryId).amount(new BigDecimal("100.00")).build(),
                SplitItemRequest.builder().categoryId(householdCategoryId).amount(new BigDecimal("0.00")).build()
        );

        CreateSplitTransactionRequest request = CreateSplitTransactionRequest.builder()
                .type(TransactionType.EXPENSE)
                .totalAmount(new BigDecimal("100.00"))
                .txnDate(LocalDate.now())
                .splits(splits)
                .build();

        BadRequestException ex = assertThrows(BadRequestException.class,
                () -> splitTransactionService.createSplitTransaction(userId, request));

        assertTrue(ex.getMessage().contains("greater than zero"));
        verify(transactionService, never()).createTransaction(any(), any());
    }

    @Test
    @DisplayName("Should throw BadRequestException when category type does not match transaction type")
    void createSplitTransaction_ThrowsBadRequest_WhenCategoryTypeMismatches() {
        List<SplitItemRequest> splits = List.of(
                SplitItemRequest.builder().categoryId(groceryCategoryId).amount(new BigDecimal("50.00")).build(),
                SplitItemRequest.builder().categoryId(salaryCategoryId).amount(new BigDecimal("50.00")).build()
        );

        CreateSplitTransactionRequest request = CreateSplitTransactionRequest.builder()
                .type(TransactionType.EXPENSE)
                .totalAmount(new BigDecimal("100.00"))
                .txnDate(LocalDate.now())
                .splits(splits)
                .build();

        when(categoryRepository.findByIdAndUserId(groceryCategoryId, userId)).thenReturn(Optional.of(groceryCategory));
        when(categoryRepository.findByIdAndUserId(salaryCategoryId, userId)).thenReturn(Optional.of(salaryCategory));

        BadRequestException ex = assertThrows(BadRequestException.class,
                () -> splitTransactionService.createSplitTransaction(userId, request));

        assertTrue(ex.getMessage().contains("does not match transaction type"));
        verify(transactionService, never()).createTransaction(any(), any());
    }

    @Test
    @DisplayName("Should throw ResourceNotFoundException when category not found or owned by another user (Anti-IDOR)")
    void createSplitTransaction_ThrowsNotFound_WhenCategoryNotFound() {
        UUID unknownCategoryId = UUID.randomUUID();
        List<SplitItemRequest> splits = List.of(
                SplitItemRequest.builder().categoryId(groceryCategoryId).amount(new BigDecimal("50.00")).build(),
                SplitItemRequest.builder().categoryId(unknownCategoryId).amount(new BigDecimal("50.00")).build()
        );

        CreateSplitTransactionRequest request = CreateSplitTransactionRequest.builder()
                .type(TransactionType.EXPENSE)
                .totalAmount(new BigDecimal("100.00"))
                .txnDate(LocalDate.now())
                .splits(splits)
                .build();

        when(categoryRepository.findByIdAndUserId(groceryCategoryId, userId)).thenReturn(Optional.of(groceryCategory));
        when(categoryRepository.findByIdAndUserId(unknownCategoryId, userId)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class,
                () -> splitTransactionService.createSplitTransaction(userId, request));

        verify(transactionService, never()).createTransaction(any(), any());
    }
}
