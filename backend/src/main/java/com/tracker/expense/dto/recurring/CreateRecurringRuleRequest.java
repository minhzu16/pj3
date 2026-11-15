package com.tracker.expense.dto.recurring;

import com.tracker.expense.model.RecurringFrequency;
import com.tracker.expense.model.TransactionType;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
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
public class CreateRecurringRuleRequest {

    @NotNull(message = "Transaction type is required")
    private TransactionType type;

    @NotNull(message = "Amount is required")
    @DecimalMin(value = "0.01", message = "Amount must be greater than zero")
    @Digits(integer = 12, fraction = 2, message = "Amount can have at most 2 decimal places")
    private BigDecimal amount;

    @NotNull(message = "Category id is required")
    private UUID categoryId;

    private UUID paymentMethodId;

    private String note;

    @NotNull(message = "Frequency is required (daily, weekly, monthly, yearly)")
    private RecurringFrequency frequency;

    @Builder.Default
    @Min(value = 1, message = "Interval count must be at least 1")
    private int intervalCount = 1;

    @NotNull(message = "Start date is required")
    private LocalDate startDate;

    private LocalDate endDate;
}
