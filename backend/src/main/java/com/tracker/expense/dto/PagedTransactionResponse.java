package com.tracker.expense.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PagedTransactionResponse {
    private List<TransactionResponse> items;
    private int page;
    private int pageSize;
    private long total;
    private TransactionTotals totals;
}
