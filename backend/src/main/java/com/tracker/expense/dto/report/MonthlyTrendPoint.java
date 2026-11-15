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
public class MonthlyTrendPoint {
    private String month;
    private BigDecimal income;
    private BigDecimal expense;
    private BigDecimal net;
}
