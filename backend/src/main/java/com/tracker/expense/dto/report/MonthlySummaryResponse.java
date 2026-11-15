package com.tracker.expense.dto.report;

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
public class MonthlySummaryResponse {
    private String month;
    @Builder.Default
    private String currency = "VND";
    private BigDecimal totalIncome;
    private BigDecimal totalExpense;
    private BigDecimal net;
    private BigDecimal previousMonthExpense;
    private BigDecimal expenseChangePercent;
}
