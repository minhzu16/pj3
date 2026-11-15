package com.tracker.expense.service.recurring;

import com.tracker.expense.model.RecurringFrequency;
import com.tracker.expense.model.RecurringRule;

import java.time.LocalDate;

public class RecurringCalculator {

    public static LocalDate calculateNextRunDate(RecurringRule rule, LocalDate afterDate) {
        int interval = Math.max(rule.getIntervalCount(), 1);
        RecurringFrequency freq = rule.getFrequency();

        switch (freq) {
            case DAILY:
                return afterDate.plusDays(interval);

            case WEEKLY:
                return afterDate.plusWeeks(interval);

            case MONTHLY: {
                int originalDay = rule.getStartDate().getDayOfMonth();
                LocalDate targetMonth = afterDate.plusMonths(interval);
                int maxDayInMonth = targetMonth.lengthOfMonth();
                int actualDay = Math.min(originalDay, maxDayInMonth);
                return targetMonth.withDayOfMonth(actualDay);
            }

            case YEARLY: {
                int originalDay = rule.getStartDate().getDayOfMonth();
                int originalMonth = rule.getStartDate().getMonthValue();
                LocalDate targetYear = afterDate.plusYears(interval);

                // Handle Feb 29 leap year clamping
                if (originalMonth == 2 && originalDay == 29 && !targetYear.isLeapYear()) {
                    return LocalDate.of(targetYear.getYear(), 2, 28);
                }
                return LocalDate.of(targetYear.getYear(), originalMonth, originalDay);
            }

            default:
                throw new IllegalArgumentException("Unsupported frequency: " + freq);
        }
    }
}
