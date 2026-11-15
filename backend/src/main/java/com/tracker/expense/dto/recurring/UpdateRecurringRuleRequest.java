package com.tracker.expense.dto.recurring;

import com.tracker.expense.model.RecurringFrequency;
import com.tracker.expense.model.TransactionType;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.Min;
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
public class UpdateRecurringRuleRequest {
    private TransactionType type;

    @DecimalMin(value = "0.01", message = "Amount must be greater than zero")
    @Digits(integer = 12, fraction = 2, message = "Amount can have at most 2 decimal places")
    private BigDecimal amount;

    private UUID categoryId;
    private UUID paymentMethodId;
    private String note;
    private RecurringFrequency frequency;

    @Min(value = 1, message = "Interval count must be at least 1")
    private Integer intervalCount;

    private LocalDate endDate;
    private Boolean isActive;
}
