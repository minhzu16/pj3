package com.tracker.expense.dto;

import com.tracker.expense.model.TransactionType;
import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
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
public class CreateSplitTransactionRequest {

    @NotNull(message = "Transaction type is required (income or expense)")
    private TransactionType type;

    @NotNull(message = "Total amount is required")
    @DecimalMin(value = "0.01", message = "Total amount must be greater than zero")
    @Digits(integer = 12, fraction = 2, message = "Total amount can have at most 2 decimal places")
    private BigDecimal totalAmount;

    @NotNull(message = "Transaction date is required")
    private LocalDate txnDate;

    private UUID paymentMethodId;

    private String note;

    @NotEmpty(message = "Splits list cannot be empty")
    @Size(min = 2, message = "Split transaction must contain at least 2 split items")
    @Valid
    private List<SplitItemRequest> splits;
}
