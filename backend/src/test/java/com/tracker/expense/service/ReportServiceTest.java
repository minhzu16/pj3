package com.tracker.expense.service;

import com.tracker.expense.dto.report.MonthlySummaryResponse;
import com.tracker.expense.repository.CategoryRepository;
import com.tracker.expense.repository.PaymentMethodRepository;
import com.tracker.expense.repository.TransactionRepository;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ReportServiceTest {

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private CategoryRepository categoryRepository;

    @Mock
    private PaymentMethodRepository paymentMethodRepository;

    @Mock
    private EntityManager entityManager;

    @InjectMocks
    private ReportService reportService;

    private final UUID userId = UUID.randomUUID();

    @Test
    void getMonthlySummary_shouldCalculateIncomeExpenseNetAndChangePercent() {
        YearMonth targetMonth = YearMonth.of(2026, 10);
        LocalDate monthStart = LocalDate.of(2026, 10, 1);
        LocalDate nextMonthStart = LocalDate.of(2026, 11, 1);
        LocalDate prevMonthStart = LocalDate.of(2026, 9, 1);

        when(transactionRepository.sumIncomeBetween(userId, monthStart, nextMonthStart))
                .thenReturn(new BigDecimal("20000000.00"));
        when(transactionRepository.sumExpenseBetween(userId, monthStart, nextMonthStart))
                .thenReturn(new BigDecimal("8000000.00"));
        when(transactionRepository.sumExpenseBetween(userId, prevMonthStart, monthStart))
                .thenReturn(new BigDecimal("10000000.00"));

        MonthlySummaryResponse response = reportService.getMonthlySummary(userId, targetMonth);

        assertNotNull(response);
        assertEquals("2026-10", response.getMonth());
        assertEquals("VND", response.getCurrency());
        assertEquals(new BigDecimal("20000000.00"), response.getTotalIncome());
        assertEquals(new BigDecimal("8000000.00"), response.getTotalExpense());
        assertEquals(new BigDecimal("12000000.00"), response.getNet());
        assertEquals(new BigDecimal("10000000.00"), response.getPreviousMonthExpense());
        // (8M - 10M) / 10M * 100 = -20.0%
        assertEquals(new BigDecimal("-20.0"), response.getExpenseChangePercent());
    }

    @Test
    void getMonthlySummary_withZeroTransactions_shouldReturnZeroesAndNullChangePercent() {
        YearMonth targetMonth = YearMonth.of(2026, 10);
        LocalDate monthStart = LocalDate.of(2026, 10, 1);
        LocalDate nextMonthStart = LocalDate.of(2026, 11, 1);
        LocalDate prevMonthStart = LocalDate.of(2026, 9, 1);

        when(transactionRepository.sumIncomeBetween(userId, monthStart, nextMonthStart))
                .thenReturn(BigDecimal.ZERO);
        when(transactionRepository.sumExpenseBetween(userId, monthStart, nextMonthStart))
                .thenReturn(BigDecimal.ZERO);
        when(transactionRepository.sumExpenseBetween(userId, prevMonthStart, monthStart))
                .thenReturn(BigDecimal.ZERO);

        MonthlySummaryResponse response = reportService.getMonthlySummary(userId, targetMonth);

        assertNotNull(response);
        assertEquals(BigDecimal.ZERO, response.getTotalIncome());
        assertEquals(BigDecimal.ZERO, response.getTotalExpense());
        assertEquals(BigDecimal.ZERO, response.getNet());
        assertNull(response.getExpenseChangePercent());
    }
}
