package com.tracker.expense.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BudgetAlertDto {
    private UUID budgetId;
    private UUID categoryId;
    private String categoryName;
    private BigDecimal spent;
    private BigDecimal amountLimit;
    private BigDecimal percent;
    private String status; // "warning" or "exceeded"
    private String message;
}
