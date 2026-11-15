package com.tracker.expense.service;

import com.tracker.expense.common.exception.BadRequestException;
import com.tracker.expense.common.exception.ResourceNotFoundException;
import com.tracker.expense.dto.CreatePaymentMethodRequest;
import com.tracker.expense.dto.PaymentMethodResponse;
import com.tracker.expense.dto.UpdatePaymentMethodRequest;
import com.tracker.expense.model.PaymentMethod;
import com.tracker.expense.repository.PaymentMethodRepository;
import com.tracker.expense.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class PaymentMethodService {

    private final PaymentMethodRepository paymentMethodRepository;
    private final TransactionRepository transactionRepository;

    @Transactional(readOnly = true)
    public List<PaymentMethodResponse> getPaymentMethods(UUID userId) {
        List<PaymentMethod> methods = paymentMethodRepository.findAllByUserIdAndArchivedFalse(userId);
        return methods.stream().map(PaymentMethodResponse::fromEntity).toList();
    }

    @Transactional(readOnly = true)
    public PaymentMethodResponse getPaymentMethodById(UUID userId, UUID id) {
        PaymentMethod method = paymentMethodRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Payment method not found"));
        return PaymentMethodResponse.fromEntity(method);
    }

    @Transactional
    public PaymentMethodResponse createPaymentMethod(UUID userId, CreatePaymentMethodRequest request) {
        String trimmedName = request.getName().trim();

        if (paymentMethodRepository.existsByUserIdAndNameIgnoreCase(userId, trimmedName)) {
            throw new BadRequestException("Payment method '" + trimmedName + "' already exists");
        }

        PaymentMethod method = PaymentMethod.builder()
                .userId(userId)
                .name(trimmedName)
                .archived(false)
                .build();

        method = paymentMethodRepository.save(method);
        return PaymentMethodResponse.fromEntity(method);
    }

    @Transactional
    public PaymentMethodResponse updatePaymentMethod(UUID userId, UUID id, UpdatePaymentMethodRequest request) {
        PaymentMethod method = paymentMethodRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Payment method not found"));

        if (request.getName() != null && !request.getName().isBlank()) {
            String newName = request.getName().trim();
            if (!newName.equalsIgnoreCase(method.getName()) &&
                    paymentMethodRepository.existsByUserIdAndNameIgnoreCase(userId, newName)) {
                throw new BadRequestException("Payment method '" + newName + "' already exists");
            }
            method.setName(newName);
        }

        if (request.getArchived() != null) {
            method.setArchived(request.getArchived());
        }

        method = paymentMethodRepository.save(method);
        return PaymentMethodResponse.fromEntity(method);
    }

    @Transactional
    public void deletePaymentMethod(UUID userId, UUID id) {
        PaymentMethod method = paymentMethodRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Payment method not found"));

        boolean hasTransactions = transactionRepository.existsByUserIdAndPaymentMethodIdAndDeletedAtIsNull(userId, id);
        if (hasTransactions) {
            method.setArchived(true);
            paymentMethodRepository.save(method);
        } else {
            paymentMethodRepository.delete(method);
        }
    }
}
