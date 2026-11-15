package com.tracker.expense.api;

import com.tracker.expense.dto.CreateSplitTransactionRequest;
import com.tracker.expense.dto.CreateTransactionRequest;
import com.tracker.expense.dto.PagedTransactionResponse;
import com.tracker.expense.dto.SplitTransactionResponse;
import com.tracker.expense.dto.TransactionFilterRequest;
import com.tracker.expense.dto.TransactionResponse;
import com.tracker.expense.dto.TransactionWithAlertsResponse;
import com.tracker.expense.dto.UpdateTransactionRequest;
import com.tracker.expense.model.TransactionType;
import com.tracker.expense.security.UserPrincipal;
import com.tracker.expense.service.CsvExportService;
import com.tracker.expense.service.SplitTransactionService;
import com.tracker.expense.service.TransactionService;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/transactions")
@RequiredArgsConstructor
public class TransactionController {

    private final TransactionService transactionService;
    private final SplitTransactionService splitTransactionService;
    private final CsvExportService csvExportService;

    @PostMapping("/split")
    public ResponseEntity<SplitTransactionResponse> createSplitTransaction(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody CreateSplitTransactionRequest request
    ) {
        SplitTransactionResponse response = splitTransactionService.createSplitTransaction(principal.getId(), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping
    public ResponseEntity<PagedTransactionResponse> getTransactions(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(required = false) TransactionType type,
            @RequestParam(value = "category_id", required = false) List<UUID> categoryIds,
            @RequestParam(value = "payment_method_id", required = false) List<UUID> paymentMethodIds,
            @RequestParam(value = "min_amount", required = false) BigDecimal minAmount,
            @RequestParam(value = "max_amount", required = false) BigDecimal maxAmount,
            @RequestParam(required = false) String q,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(value = "page_size", defaultValue = "20") int pageSize,
            @RequestParam(value = "sort_by", defaultValue = "txnDate") String sortBy,
            @RequestParam(value = "sort_direction", defaultValue = "DESC") String sortDirection
    ) {
        TransactionFilterRequest filter = TransactionFilterRequest.builder()
                .from(from)
                .to(to)
                .type(type)
                .categoryIds(categoryIds)
                .paymentMethodIds(paymentMethodIds)
                .minAmount(minAmount)
                .maxAmount(maxAmount)
                .q(q)
                .page(page)
                .pageSize(pageSize)
                .sortBy(sortBy)
                .sortDirection(sortDirection)
                .build();

        PagedTransactionResponse response = transactionService.getTransactions(principal.getId(), filter);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/export.csv")
    public void exportTransactionsCsv(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(required = false) TransactionType type,
            @RequestParam(value = "category_id", required = false) List<UUID> categoryIds,
            @RequestParam(value = "payment_method_id", required = false) List<UUID> paymentMethodIds,
            @RequestParam(value = "min_amount", required = false) BigDecimal minAmount,
            @RequestParam(value = "max_amount", required = false) BigDecimal maxAmount,
            @RequestParam(required = false) String q,
            HttpServletResponse response
    ) throws IOException {
        TransactionFilterRequest filter = TransactionFilterRequest.builder()
                .from(from)
                .to(to)
                .type(type)
                .categoryIds(categoryIds)
                .paymentMethodIds(paymentMethodIds)
                .minAmount(minAmount)
                .maxAmount(maxAmount)
                .q(q)
                .build();

        List<TransactionResponse> transactions = transactionService.getAllFilteredTransactions(principal.getId(), filter);

        response.setContentType("text/csv; charset=UTF-8");
        response.setHeader(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"transactions.csv\"");

        csvExportService.writeTransactionsCsv(transactions, response.getWriter());
    }

    @PostMapping
    public ResponseEntity<TransactionWithAlertsResponse> createTransaction(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody CreateTransactionRequest request
    ) {
        TransactionWithAlertsResponse response = transactionService.createTransaction(principal.getId(), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/{id}")
    public ResponseEntity<TransactionResponse> getTransactionById(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID id
    ) {
        TransactionResponse response = transactionService.getTransactionById(principal.getId(), id);
        return ResponseEntity.ok(response);
    }

    @PatchMapping("/{id}")
    public ResponseEntity<TransactionResponse> updateTransaction(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID id,
            @RequestBody UpdateTransactionRequest request
    ) {
        TransactionResponse response = transactionService.updateTransaction(principal.getId(), id, request);
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTransaction(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID id
    ) {
        transactionService.deleteTransaction(principal.getId(), id);
        return ResponseEntity.noContent().build();
    }
}
