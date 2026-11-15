package com.tracker.expense.dto.budget;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.Max;
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
public class CreateBudgetRequest {

    // categoryId is nullable: NULL = monthly total budget
    private UUID categoryId;

    @NotNull(message = "Month is required")
    private LocalDate month;

    @NotNull(message = "Amount limit is required")
    @DecimalMin(value = "0.01", message = "Amount limit must be greater than zero")
    @Digits(integer = 12, fraction = 2, message = "Amount can have at most 2 decimal places")
    private BigDecimal amountLimit;

    @Builder.Default
    @Min(value = 1, message = "Threshold must be between 1 and 100")
    @Max(value = 100, message = "Threshold must be between 1 and 100")
    private short alertThreshold = 80;
}
