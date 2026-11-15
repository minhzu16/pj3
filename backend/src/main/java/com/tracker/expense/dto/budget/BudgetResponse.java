package com.tracker.expense.dto.budget;

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
public class BudgetResponse {
    private UUID id;
    private UUID categoryId;
    private String categoryName;
    private String categoryColor;
    private LocalDate month;
    private BigDecimal amountLimit;
    private BigDecimal spent;
    private BigDecimal remaining;
    private BigDecimal percent;
    private String status; // "safe", "warning", "exceeded"
    private short alertThreshold;
    private Instant createdAt;
}
