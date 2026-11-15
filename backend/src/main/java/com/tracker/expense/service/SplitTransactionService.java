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
import com.tracker.expense.model.PaymentMethod;
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
        if (request.getSplits() == null || request.getSplits().size() < 2) {
            throw new BadRequestException("Split transaction must contain at least 2 split items");
        }

        if (request.getTotalAmount() == null || request.getTotalAmount().compareTo(BigDecimal.ZERO) <= 0) {
            throw new BadRequestException("Total amount must be greater than zero");
        }

        // Validate individual split amounts and calculate the total sum
        BigDecimal sumSplits = BigDecimal.ZERO;
        for (SplitItemRequest split : request.getSplits()) {
            if (split.getAmount() == null || split.getAmount().compareTo(BigDecimal.ZERO) <= 0) {
                throw new BadRequestException("Split amount must be greater than zero");
            }
            sumSplits = sumSplits.add(split.getAmount());
        }

        // Strict Sum Invariant Check: sum(splits) == totalAmount
        if (sumSplits.compareTo(request.getTotalAmount()) != 0) {
            log.warn("Split transaction sum invariant violation for user {}: splits total={}, expected total={}",
                    userId, sumSplits, request.getTotalAmount());
            throw new BadRequestException("Split amounts total (" + sumSplits + ") does not equal total transaction amount (" + request.getTotalAmount() + ")");
        }

        // Validate payment method ownership if specified
        PaymentMethodResponse paymentMethodResponse = null;
        if (request.getPaymentMethodId() != null) {
            PaymentMethod pm = paymentMethodRepository.findByIdAndUserId(request.getPaymentMethodId(), userId)
                    .orElseThrow(() -> new ResourceNotFoundException("Payment method not found"));
            paymentMethodResponse = PaymentMethodResponse.fromEntity(pm);
        }

        // Validate each category's existence and ownership by user
        for (SplitItemRequest split : request.getSplits()) {
            Category category = categoryRepository.findByIdAndUserId(split.getCategoryId(), userId)
                    .orElseThrow(() -> new ResourceNotFoundException("Category not found"));

            if (category.getType() != request.getType()) {
                throw new BadRequestException("Category type (" + category.getType().getValue()
                        + ") does not match transaction type (" + request.getType().getValue() + ")");
            }
        }

        // Execute split transaction persistence
        UUID splitGroupId = UUID.randomUUID();
        List<TransactionWithAlertsResponse> splitResponses = new ArrayList<>();
        int totalItems = request.getSplits().size();

        for (int i = 0; i < totalItems; i++) {
            SplitItemRequest split = request.getSplits().get(i);
            String itemNote = split.getNote();
            String prefix = "[Split " + (i + 1) + "/" + totalItems + "]";

            String finalNote;
            if (itemNote != null && !itemNote.isBlank()) {
                finalNote = prefix + " " + itemNote + (request.getNote() != null ? " (" + request.getNote() + ")" : "");
            } else if (request.getNote() != null && !request.getNote().isBlank()) {
                finalNote = prefix + " " + request.getNote();
            } else {
                finalNote = prefix;
            }

            CreateTransactionRequest singleTxnReq = CreateTransactionRequest.builder()
                    .type(request.getType())
                    .amount(split.getAmount())
                    .txnDate(request.getTxnDate())
                    .categoryId(split.getCategoryId())
                    .paymentMethodId(request.getPaymentMethodId())
                    .note(finalNote)
                    .build();

            TransactionWithAlertsResponse resp = transactionService.createTransaction(userId, singleTxnReq);
            splitResponses.add(resp);
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
                .splitCount(splitResponses.size())
                .splitTransactions(splitResponses)
                .createdAt(Instant.now())
                .build();
    }
}
