package com.tracker.expense.service;

import com.tracker.expense.common.exception.BadRequestException;
import com.tracker.expense.common.exception.ResourceNotFoundException;
import com.tracker.expense.dto.CreateSplitTransactionRequest;
import com.tracker.expense.dto.CreateTransactionRequest;
import com.tracker.expense.dto.PaymentMethodResponse;
import com.tracker.expense.dto.SplitItemRequest;
import com.tracker.expense.dto.SplitTransactionResponse;
import com.tracker.expense.dto.TransactionWithAlertsResponse;
import com.tracker.expense.model.Category;
import com.tracker.expense.repository.CategoryRepository;
import com.tracker.expense.repository.PaymentMethodRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class SplitTransactionService {

    private final TransactionService transactionService;
    private final CategoryRepository categoryRepository;
    private final PaymentMethodRepository paymentMethodRepository;

    /**
     * Creates a split transaction ensuring the mathematical sum invariant holds:
     * sum(splits.amount) == request.totalAmount (evaluated using BigDecimal.compareTo() == 0).
     *
     * Adheres to real-world financial standards seen in YNAB, Copilot Money, and Monarch Money:
     * 1. Requires at least 2 distinct split allocations.
     * 2. Rejects negative or zero split values.
     * 3. Guarantees atomic creation of child transactions across respective categories so budget
     *    thresholds and category analytics reflect exact expenditures.
     */
    @Transactional
    public SplitTransactionResponse createSplitTransaction(UUID userId, CreateSplitTransactionRequest request) {
        // Guard clauses: fast boundary checks
        if (request.getSplits() == null || request.getSplits().size() < 2) {
            throw new BadRequestException("Split transaction must contain at least 2 split items");
        }
        if (request.getTotalAmount() == null || request.getTotalAmount().compareTo(BigDecimal.ZERO) <= 0) {
            throw new BadRequestException("Total amount must be greater than zero");
        }

        // Validate individual split amounts and calculate total via stream reduce
        BigDecimal sumSplits = request.getSplits().stream()
                .map(split -> {
                    if (split.getAmount() == null || split.getAmount().compareTo(BigDecimal.ZERO) <= 0) {
                        throw new BadRequestException("Split amount must be greater than zero");
                    }
                    return split.getAmount();
                })
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // Strict Sum Invariant Check: sum(splits) == totalAmount
        if (sumSplits.compareTo(request.getTotalAmount()) != 0) {
            log.warn("Split sum violation for user {}: splits total={}, expected total={}",
                    userId, sumSplits, request.getTotalAmount());
            throw new BadRequestException("Split amounts total (" + sumSplits + ") does not equal total transaction amount (" + request.getTotalAmount() + ")");
        }

        // Validate payment method ownership if specified
        PaymentMethodResponse paymentMethodResponse = request.getPaymentMethodId() == null ? null :
                paymentMethodRepository.findByIdAndUserId(request.getPaymentMethodId(), userId)
                        .map(PaymentMethodResponse::fromEntity)
                        .orElseThrow(() -> new ResourceNotFoundException("Payment method not found"));

        // Validate categories upfront (fail-fast)
        for (SplitItemRequest split : request.getSplits()) {
            Category category = categoryRepository.findByIdAndUserId(split.getCategoryId(), userId)
                    .orElseThrow(() -> new ResourceNotFoundException("Category not found"));
            if (category.getType() != request.getType()) {
                throw new BadRequestException("Category type (" + category.getType().getValue()
                        + ") does not match transaction type (" + request.getType().getValue() + ")");
            }
        }

        // Persist split transactions
        UUID splitGroupId = UUID.randomUUID();
        int totalItems = request.getSplits().size();
        List<TransactionWithAlertsResponse> splitResponses = new ArrayList<>(totalItems);

        for (int i = 0; i < totalItems; i++) {
            SplitItemRequest split = request.getSplits().get(i);
            String note = buildSplitNote(split.getNote(), request.getNote(), i + 1, totalItems);

            CreateTransactionRequest singleTxnReq = CreateTransactionRequest.builder()
                    .type(request.getType())
                    .amount(split.getAmount())
                    .txnDate(request.getTxnDate())
                    .categoryId(split.getCategoryId())
                    .paymentMethodId(request.getPaymentMethodId())
                    .note(note)
                    .build();

            splitResponses.add(transactionService.createTransaction(userId, singleTxnReq));
        }

        log.info("Successfully created split transaction group {} with {} items for user {}",
                splitGroupId, totalItems, userId);

        return SplitTransactionResponse.builder()
                .splitGroupId(splitGroupId)
                .type(request.getType())
                .totalAmount(request.getTotalAmount())
                .txnDate(request.getTxnDate())
                .paymentMethod(paymentMethodResponse)
                .mainNote(request.getNote())
                .splitCount(totalItems)
                .splitTransactions(splitResponses)
                .createdAt(Instant.now())
                .build();
    }

    private static String buildSplitNote(String itemNote, String mainNote, int index, int total) {
        String prefix = "[Split " + index + "/" + total + "]";
        if (itemNote != null && !itemNote.isBlank()) {
            return (mainNote != null && !mainNote.isBlank())
                    ? prefix + " " + itemNote + " (" + mainNote + ")"
                    : prefix + " " + itemNote;
        }
        return (mainNote != null && !mainNote.isBlank()) ? prefix + " " + mainNote : prefix;
    }
}
