package com.tracker.expense.dto.budget;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdateBudgetRequest {

    @DecimalMin(value = "0.01", message = "Amount limit must be greater than zero")
    @Digits(integer = 12, fraction = 2, message = "Amount can have at most 2 decimal places")
    private BigDecimal amountLimit;

    @Min(value = 1, message = "Threshold must be between 1 and 100")
    @Max(value = 100, message = "Threshold must be between 1 and 100")
    private Short alertThreshold;
}
