package com.tracker.expense.dto.recurring;

import com.tracker.expense.dto.CategoryResponse;
import com.tracker.expense.dto.PaymentMethodResponse;
import com.tracker.expense.model.RecurringFrequency;
import com.tracker.expense.model.RecurringRule;
import com.tracker.expense.model.TransactionType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RecurringRuleResponse {
    private UUID id;
    private TransactionType type;
    private BigDecimal amount;
    private CategoryResponse category;
    private PaymentMethodResponse paymentMethod;
    private String note;
    private RecurringFrequency frequency;
    private int intervalCount;
    private LocalDate startDate;
    private LocalDate endDate;
    private LocalDate nextRunDate;
    private boolean isActive;
    private Instant createdAt;

    public static RecurringRuleResponse fromEntity(
            RecurringRule rule,
            CategoryResponse category,
            PaymentMethodResponse paymentMethod
    ) {
        if (rule == null) {
            return null;
        }
        return RecurringRuleResponse.builder()
                .id(rule.getId())
                .type(rule.getType())
                .amount(rule.getAmount())
                .category(category)
                .paymentMethod(paymentMethod)
                .note(rule.getNote())
                .frequency(rule.getFrequency())
                .intervalCount(rule.getIntervalCount())
                .startDate(rule.getStartDate())
                .endDate(rule.getEndDate())
                .nextRunDate(rule.getNextRunDate())
                .isActive(rule.isActive())
                .createdAt(rule.getCreatedAt())
                .build();
    }
}
