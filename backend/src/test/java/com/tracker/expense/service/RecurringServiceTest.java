package com.tracker.expense.service;

import com.tracker.expense.model.RecurringFrequency;
import com.tracker.expense.model.RecurringRule;
import com.tracker.expense.model.Transaction;
import com.tracker.expense.model.TransactionType;
import com.tracker.expense.repository.CategoryRepository;
import com.tracker.expense.repository.PaymentMethodRepository;
import com.tracker.expense.repository.RecurringRuleRepository;
import com.tracker.expense.repository.TransactionRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class RecurringServiceTest {

    @Mock
    private RecurringRuleRepository recurringRuleRepository;

    @Mock
    private CategoryRepository categoryRepository;

    @Mock
    private PaymentMethodRepository paymentMethodRepository;

    @Mock
    private TransactionRepository transactionRepository;

    @InjectMocks
    private RecurringService recurringService;

    private final UUID userId = UUID.randomUUID();
    private final UUID ruleId = UUID.randomUUID();
    private final UUID categoryId = UUID.randomUUID();

    @Test
    void processRecurringRules_shouldGenerateTransactionAndAdvanceNextRunDate() {
        LocalDate today = LocalDate.of(2026, 10, 5);

        RecurringRule rule = RecurringRule.builder()
                .id(ruleId)
                .userId(userId)
                .type(TransactionType.EXPENSE)
                .amount(new BigDecimal("5000000.00"))
                .categoryId(categoryId)
                .frequency(RecurringFrequency.MONTHLY)
                .intervalCount(1)
                .startDate(LocalDate.of(2026, 10, 5))
                .nextRunDate(LocalDate.of(2026, 10, 5))
                .isActive(true)
                .build();

        when(recurringRuleRepository.findAllByIsActiveTrueAndNextRunDateLessThanEqual(today))
                .thenReturn(List.of(rule));
        when(transactionRepository.existsByRecurringRuleIdAndOccurrenceDate(ruleId, today))
                .thenReturn(false);

        int count = recurringService.processRecurringRules(today);

        assertEquals(1, count);
        verify(transactionRepository).save(any(Transaction.class));
        assertEquals(LocalDate.of(2026, 11, 5), rule.getNextRunDate());
        verify(recurringRuleRepository).save(rule);
    }

    @Test
    void processRecurringRules_idempotent_shouldSkipIfTransactionAlreadyExists() {
        LocalDate today = LocalDate.of(2026, 10, 5);

        RecurringRule rule = RecurringRule.builder()
                .id(ruleId)
                .userId(userId)
                .type(TransactionType.EXPENSE)
                .amount(new BigDecimal("5000000.00"))
                .categoryId(categoryId)
                .frequency(RecurringFrequency.MONTHLY)
                .intervalCount(1)
                .startDate(LocalDate.of(2026, 10, 5))
                .nextRunDate(LocalDate.of(2026, 10, 5))
                .isActive(true)
                .build();

        when(recurringRuleRepository.findAllByIsActiveTrueAndNextRunDateLessThanEqual(today))
                .thenReturn(List.of(rule));
        // Transaction already generated previously for this rule and occurrence!
        when(transactionRepository.existsByRecurringRuleIdAndOccurrenceDate(ruleId, today))
                .thenReturn(true);

        int count = recurringService.processRecurringRules(today);

        assertEquals(0, count);
        verify(transactionRepository, never()).save(any(Transaction.class));
        assertEquals(LocalDate.of(2026, 11, 5), rule.getNextRunDate());
        verify(recurringRuleRepository).save(rule);
    }
}
