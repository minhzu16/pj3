package com.tracker.expense.dto.recurring;

import com.tracker.expense.model.TransactionType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpcomingRecurringItem {
    private UUID ruleId;
    private TransactionType type;
    private BigDecimal amount;
    private String categoryName;
    private String categoryColor;
    private String paymentMethodName;
    private String note;
    private LocalDate dueDate;
}
