package com.tracker.expense.api;

import com.tracker.expense.dto.CreatePaymentMethodRequest;
import com.tracker.expense.dto.PaymentMethodResponse;
import com.tracker.expense.dto.UpdatePaymentMethodRequest;
import com.tracker.expense.security.UserPrincipal;
import com.tracker.expense.service.PaymentMethodService;
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
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/payment-methods")
@RequiredArgsConstructor
public class PaymentMethodController {

    private final PaymentMethodService paymentMethodService;

    @GetMapping
    public ResponseEntity<List<PaymentMethodResponse>> getPaymentMethods(
            @AuthenticationPrincipal UserPrincipal principal
    ) {
        List<PaymentMethodResponse> methods = paymentMethodService.getPaymentMethods(principal.getId());
        return ResponseEntity.ok(methods);
    }

    @GetMapping("/{id}")
    public ResponseEntity<PaymentMethodResponse> getPaymentMethodById(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID id
    ) {
        PaymentMethodResponse method = paymentMethodService.getPaymentMethodById(principal.getId(), id);
        return ResponseEntity.ok(method);
    }

    @PostMapping
    public ResponseEntity<PaymentMethodResponse> createPaymentMethod(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody CreatePaymentMethodRequest request
    ) {
        PaymentMethodResponse method = paymentMethodService.createPaymentMethod(principal.getId(), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(method);
    }

    @PatchMapping("/{id}")
    public ResponseEntity<PaymentMethodResponse> updatePaymentMethod(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID id,
            @RequestBody UpdatePaymentMethodRequest request
    ) {
        PaymentMethodResponse method = paymentMethodService.updatePaymentMethod(principal.getId(), id, request);
        return ResponseEntity.ok(method);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletePaymentMethod(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID id
    ) {
        paymentMethodService.deletePaymentMethod(principal.getId(), id);
        return ResponseEntity.noContent().build();
    }
}
