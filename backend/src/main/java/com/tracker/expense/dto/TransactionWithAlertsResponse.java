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
public class TransactionWithAlertsResponse {
    private TransactionResponse transaction;
    private List<BudgetAlertDto> budgetAlerts;
}
