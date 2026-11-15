package com.tracker.expense.api;

import com.tracker.expense.dto.recurring.CreateRecurringRuleRequest;
import com.tracker.expense.dto.recurring.RecurringRuleResponse;
import com.tracker.expense.dto.recurring.UpcomingRecurringItem;
import com.tracker.expense.dto.recurring.UpdateRecurringRuleRequest;
import com.tracker.expense.security.UserPrincipal;
import com.tracker.expense.service.RecurringService;
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

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/recurring")
@RequiredArgsConstructor
public class RecurringController {

    private final RecurringService recurringService;

    @GetMapping
    public ResponseEntity<List<RecurringRuleResponse>> getRules(
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        List<RecurringRuleResponse> rules = recurringService.getRules(principal.getId());
        return ResponseEntity.ok(rules);
    }

    @GetMapping("/{id}")
    public ResponseEntity<RecurringRuleResponse> getRuleById(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID id
    ) {
        RecurringRuleResponse rule = recurringService.getRuleById(principal.getId(), id);
        return ResponseEntity.ok(rule);
    }

    @PostMapping
    public ResponseEntity<RecurringRuleResponse> createRule(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody CreateRecurringRuleRequest request
    ) {
        RecurringRuleResponse rule = recurringService.createRule(principal.getId(), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(rule);
    }

    @PatchMapping("/{id}")
    public ResponseEntity<RecurringRuleResponse> updateRule(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID id,
            @Valid @RequestBody UpdateRecurringRuleRequest request
    ) {
        RecurringRuleResponse rule = recurringService.updateRule(principal.getId(), id, request);
        return ResponseEntity.ok(rule);
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<RecurringRuleResponse> toggleStatus(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID id,
            @RequestBody Map<String, Boolean> body
    ) {
        boolean isActive = body.getOrDefault("is_active", body.getOrDefault("isActive", true));
        RecurringRuleResponse rule = recurringService.toggleStatus(principal.getId(), id, isActive);
        return ResponseEntity.ok(rule);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteRule(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID id
    ) {
        recurringService.deleteRule(principal.getId(), id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/upcoming")
    public ResponseEntity<List<UpcomingRecurringItem>> getUpcoming(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam(defaultValue = "30") int days
    ) {
        List<UpcomingRecurringItem> items = recurringService.getUpcoming(principal.getId(), days);
        return ResponseEntity.ok(items);
    }
}
