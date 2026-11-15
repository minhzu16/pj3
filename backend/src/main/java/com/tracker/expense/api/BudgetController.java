package com.tracker.expense.api;

import com.tracker.expense.dto.budget.BudgetResponse;
import com.tracker.expense.dto.budget.CopyBudgetsRequest;
import com.tracker.expense.dto.budget.CreateBudgetRequest;
import com.tracker.expense.dto.budget.UpdateBudgetRequest;
import com.tracker.expense.security.UserPrincipal;
import com.tracker.expense.service.BudgetService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
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

import java.time.YearMonth;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/budgets")
@RequiredArgsConstructor
public class BudgetController {

    private final BudgetService budgetService;

    @GetMapping
    public ResponseEntity<List<BudgetResponse>> getBudgets(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam(required = false) String month
    ) {
        YearMonth targetMonth = month != null && !month.isBlank()
                ? YearMonth.parse(month)
                : YearMonth.now();

        List<BudgetResponse> budgets = budgetService.getBudgets(principal.getId(), targetMonth);
        return ResponseEntity.ok(budgets);
    }

    @GetMapping("/{id}")
    public ResponseEntity<BudgetResponse> getBudgetById(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID id
    ) {
        BudgetResponse budget = budgetService.getBudgetById(principal.getId(), id);
        return ResponseEntity.ok(budget);
    }

    @PostMapping
    public ResponseEntity<BudgetResponse> createBudget(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody CreateBudgetRequest request
    ) {
        BudgetResponse budget = budgetService.createBudget(principal.getId(), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(budget);
    }

    @PatchMapping("/{id}")
    public ResponseEntity<BudgetResponse> updateBudget(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID id,
            @Valid @RequestBody UpdateBudgetRequest request
    ) {
        BudgetResponse budget = budgetService.updateBudget(principal.getId(), id, request);
        return ResponseEntity.ok(budget);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteBudget(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID id
    ) {
        budgetService.deleteBudget(principal.getId(), id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/copy")
    public ResponseEntity<List<BudgetResponse>> copyBudgets(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam(required = false) String from,
            @RequestParam(required = false) String to,
            @RequestBody(required = false) CopyBudgetsRequest body
    ) {
        String fromStr = from != null ? from : (body != null ? body.getFrom() : null);
        String toStr = to != null ? to : (body != null ? body.getTo() : null);

        if (fromStr == null || toStr == null) {
            return ResponseEntity.badRequest().build();
        }

        YearMonth fromMonth = YearMonth.parse(fromStr);
        YearMonth toMonth = YearMonth.parse(toStr);

        List<BudgetResponse> copied = budgetService.copyBudgets(principal.getId(), fromMonth, toMonth);
        return ResponseEntity.ok(copied);
    }
}
