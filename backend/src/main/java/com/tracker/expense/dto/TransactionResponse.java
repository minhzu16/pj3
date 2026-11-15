package com.tracker.expense.dto;

import com.tracker.expense.model.Transaction;
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
public class TransactionResponse {
    private UUID id;
    private TransactionType type;
    private BigDecimal amount;
    private LocalDate txnDate;
    private CategoryResponse category;
    private PaymentMethodResponse paymentMethod;
    private String note;
    private UUID recurringRuleId;
    private LocalDate occurrenceDate;
    private Instant createdAt;
    private Instant updatedAt;

    public static TransactionResponse fromEntity(Transaction txn, CategoryResponse category, PaymentMethodResponse paymentMethod) {
        if (txn == null) {
            return null;
        }
        return TransactionResponse.builder()
                .id(txn.getId())
                .type(txn.getType())
                .amount(txn.getAmount())
                .txnDate(txn.getTxnDate())
                .category(category)
                .paymentMethod(paymentMethod)
                .note(txn.getNote())
                .recurringRuleId(txn.getRecurringRuleId())
                .occurrenceDate(txn.getOccurrenceDate())
                .createdAt(txn.getCreatedAt())
                .updatedAt(txn.getUpdatedAt())
                .build();
    }
}
