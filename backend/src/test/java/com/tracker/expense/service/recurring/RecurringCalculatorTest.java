package com.tracker.expense.service.recurring;

import com.tracker.expense.model.RecurringFrequency;
import com.tracker.expense.model.RecurringRule;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.assertEquals;

class RecurringCalculatorTest {

    @Test
    void calculateNextRunDate_daily() {
        RecurringRule rule = RecurringRule.builder()
                .frequency(RecurringFrequency.DAILY)
                .intervalCount(2)
                .startDate(LocalDate.of(2026, 10, 1))
                .build();

        LocalDate next = RecurringCalculator.calculateNextRunDate(rule, LocalDate.of(2026, 10, 1));
        assertEquals(LocalDate.of(2026, 10, 3), next);
    }

    @Test
    void calculateNextRunDate_weekly() {
        RecurringRule rule = RecurringRule.builder()
                .frequency(RecurringFrequency.WEEKLY)
                .intervalCount(1)
                .startDate(LocalDate.of(2026, 10, 1))
                .build();

        LocalDate next = RecurringCalculator.calculateNextRunDate(rule, LocalDate.of(2026, 10, 1));
        assertEquals(LocalDate.of(2026, 10, 8), next);
    }

    @Test
    void calculateNextRunDate_monthly_clampsToEndOfMonth_nonLeapYear() {
        // Started on Jan 31, 2026
        RecurringRule rule = RecurringRule.builder()
                .frequency(RecurringFrequency.MONTHLY)
                .intervalCount(1)
                .startDate(LocalDate.of(2026, 1, 31))
                .build();

        // Jan 31 -> Feb 28, 2026 (non leap year)
        LocalDate febDate = RecurringCalculator.calculateNextRunDate(rule, LocalDate.of(2026, 1, 31));
        assertEquals(LocalDate.of(2026, 2, 28), febDate);

        // Next month from Feb 28 should preserve the original day 31 -> Mar 31, 2026!
        LocalDate marDate = RecurringCalculator.calculateNextRunDate(rule, febDate);
        assertEquals(LocalDate.of(2026, 3, 31), marDate);

        // Next month from Mar 31 -> Apr 30, 2026
        LocalDate aprDate = RecurringCalculator.calculateNextRunDate(rule, marDate);
        assertEquals(LocalDate.of(2026, 4, 30), aprDate);
    }

    @Test
    void calculateNextRunDate_monthly_clampsToEndOfMonth_leapYear2028() {
        // Started on Jan 31, 2028
        RecurringRule rule = RecurringRule.builder()
                .frequency(RecurringFrequency.MONTHLY)
                .intervalCount(1)
                .startDate(LocalDate.of(2028, 1, 31))
                .build();

        // 2028 is a leap year -> Feb 29!
        LocalDate febDate = RecurringCalculator.calculateNextRunDate(rule, LocalDate.of(2028, 1, 31));
        assertEquals(LocalDate.of(2028, 2, 29), febDate);
    }

    @Test
    void calculateNextRunDate_yearly_leapYearToNonLeapYear() {
        // Feb 29, 2024 (leap year)
        RecurringRule rule = RecurringRule.builder()
                .frequency(RecurringFrequency.YEARLY)
                .intervalCount(1)
                .startDate(LocalDate.of(2024, 2, 29))
                .build();

        // In 2025 (not leap year), clamps to Feb 28
        LocalDate nextYear = RecurringCalculator.calculateNextRunDate(rule, LocalDate.of(2024, 2, 29));
        assertEquals(LocalDate.of(2025, 2, 28), nextYear);
    }
}
