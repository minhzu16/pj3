package com.tracker.expense.dto;

import com.tracker.expense.model.TransactionType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TransactionFilterRequest {
    private LocalDate from;
    private LocalDate to;
    private TransactionType type;
    private List<UUID> categoryIds;
    private List<UUID> paymentMethodIds;
    private BigDecimal minAmount;
    private BigDecimal maxAmount;
    private String q;

    @Builder.Default
    private int page = 1;

    @Builder.Default
    private int pageSize = 20;

    @Builder.Default
    private String sortBy = "txnDate";

    @Builder.Default
    private String sortDirection = "DESC";
}
