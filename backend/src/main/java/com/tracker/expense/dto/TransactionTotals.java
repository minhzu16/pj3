package com.tracker.expense.dto;

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
public class TransactionTotals {
    @Builder.Default
    private BigDecimal income = BigDecimal.ZERO;

    @Builder.Default
    private BigDecimal expense = BigDecimal.ZERO;
}
