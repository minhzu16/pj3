package com.tracker.expense.service;

import com.tracker.expense.common.exception.BadRequestException;
import com.tracker.expense.dto.budget.BudgetResponse;
import com.tracker.expense.dto.budget.CreateBudgetRequest;
import com.tracker.expense.model.Budget;
import com.tracker.expense.model.Category;
import com.tracker.expense.model.TransactionType;
import com.tracker.expense.repository.BudgetRepository;
import com.tracker.expense.repository.CategoryRepository;
import com.tracker.expense.repository.TransactionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class BudgetServiceTest {

    @Mock
    private BudgetRepository budgetRepository;

    @Mock
    private CategoryRepository categoryRepository;

    @Mock
    private TransactionRepository transactionRepository;

    @InjectMocks
    private BudgetService budgetService;

    private final UUID userId = UUID.randomUUID();
    private final UUID categoryId = UUID.randomUUID();

    private Category expenseCategory;
    private Category incomeCategory;

    @BeforeEach
    void setUp() {
        expenseCategory = Category.builder()
                .id(categoryId)
                .userId(userId)
                .name("Ăn uống")
                .type(TransactionType.EXPENSE)
                .color("#FF5722")
                .build();

        incomeCategory = Category.builder()
                .id(categoryId)
                .userId(userId)
                .name("Lương")
                .type(TransactionType.INCOME)
                .build();
    }

    @Test
    void createBudget_categoryExpense_success() {
        LocalDate month = LocalDate.of(2026, 10, 15); // will be normalized to day 1
        CreateBudgetRequest request = CreateBudgetRequest.builder()
                .categoryId(categoryId)
                .month(month)
                .amountLimit(new BigDecimal("2000000.00"))
                .alertThreshold((short) 80)
                .build();

        LocalDate monthStart = LocalDate.of(2026, 10, 1);
        when(categoryRepository.findByIdAndUserId(categoryId, userId)).thenReturn(Optional.of(expenseCategory));
        when(budgetRepository.findByUserIdAndCategoryIdAndMonth(userId, categoryId, monthStart))
                .thenReturn(Optional.empty());

        Budget savedBudget = Budget.builder()
                .id(UUID.randomUUID())
                .userId(userId)
                .categoryId(categoryId)
                .month(monthStart)
                .amountLimit(new BigDecimal("2000000.00"))
                .alertThreshold((short) 80)
                .build();

        when(budgetRepository.save(any(Budget.class))).thenReturn(savedBudget);
        when(transactionRepository.sumExpenseForCategoryBetween(any(), any(), any(), any()))
                .thenReturn(BigDecimal.ZERO);

        BudgetResponse response = budgetService.createBudget(userId, request);

        assertNotNull(response);
        assertEquals("Ăn uống", response.getCategoryName());
        assertEquals(new BigDecimal("2000000.00"), response.getAmountLimit());
        assertEquals("safe", response.getStatus());
    }

    @Test
    void createBudget_incomeCategory_shouldThrowBadRequestException() {
        CreateBudgetRequest request = CreateBudgetRequest.builder()
                .categoryId(categoryId)
                .month(LocalDate.of(2026, 10, 1))
                .amountLimit(new BigDecimal("2000000.00"))
                .build();

        when(categoryRepository.findByIdAndUserId(categoryId, userId)).thenReturn(Optional.of(incomeCategory));

        assertThrows(BadRequestException.class, () -> budgetService.createBudget(userId, request));
    }

    @Test
    void getBudgets_shouldEvaluateSafeWarningAndExceededCorrectly() {
        YearMonth targetMonth = YearMonth.of(2026, 10);
        LocalDate monthStart = LocalDate.of(2026, 10, 1);
        LocalDate nextMonthStart = LocalDate.of(2026, 11, 1);

        UUID cat1Id = UUID.randomUUID();
        UUID cat2Id = UUID.randomUUID();
        UUID cat3Id = UUID.randomUUID();

        Budget bSafe = Budget.builder().id(UUID.randomUUID()).userId(userId).categoryId(cat1Id).month(monthStart)
                .amountLimit(new BigDecimal("1000000.00")).alertThreshold((short) 80).build();
        Budget bWarning = Budget.builder().id(UUID.randomUUID()).userId(userId).categoryId(cat2Id).month(monthStart)
                .amountLimit(new BigDecimal("1000000.00")).alertThreshold((short) 80).build();
        Budget bExceeded = Budget.builder().id(UUID.randomUUID()).userId(userId).categoryId(cat3Id).month(monthStart)
                .amountLimit(new BigDecimal("1000000.00")).alertThreshold((short) 80).build();

        when(budgetRepository.findAllByUserIdAndMonth(userId, monthStart))
                .thenReturn(List.of(bSafe, bWarning, bExceeded));

        Category cat1 = Category.builder().id(cat1Id).userId(userId).name("Safe").build();
        Category cat2 = Category.builder().id(cat2Id).userId(userId).name("Warning").build();
        Category cat3 = Category.builder().id(cat3Id).userId(userId).name("Exceeded").build();

        when(categoryRepository.findAllById(any())).thenReturn(List.of(cat1, cat2, cat3));

        when(transactionRepository.sumExpenseForCategoryBetween(userId, cat1Id, monthStart, nextMonthStart))
                .thenReturn(new BigDecimal("500000.00")); // 50%
        when(transactionRepository.sumExpenseForCategoryBetween(userId, cat2Id, monthStart, nextMonthStart))
                .thenReturn(new BigDecimal("800000.00")); // 80% (Warning)
        when(transactionRepository.sumExpenseForCategoryBetween(userId, cat3Id, monthStart, nextMonthStart))
                .thenReturn(new BigDecimal("1200000.00")); // 120% (Exceeded)

        List<BudgetResponse> responses = budgetService.getBudgets(userId, targetMonth);

        assertEquals(3, responses.size());
        assertEquals("safe", responses.get(0).getStatus());
        assertEquals("warning", responses.get(1).getStatus());
        assertEquals("exceeded", responses.get(2).getStatus());
    }
}
