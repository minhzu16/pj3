package com.tracker.expense.dto.report;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DailyReportPoint {
    private LocalDate date;
    private BigDecimal income;
    private BigDecimal expense;
    private BigDecimal cumulativeExpense;
}
