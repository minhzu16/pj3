package com.tracker.expense.dto;

import com.tracker.expense.model.TransactionType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SplitTransactionResponse {
    private UUID splitGroupId;
    private TransactionType type;
    private BigDecimal totalAmount;
    private LocalDate txnDate;
    private PaymentMethodResponse paymentMethod;
    private String mainNote;
    private int splitCount;
    private List<TransactionWithAlertsResponse> splitTransactions;
    private Instant createdAt;
}
