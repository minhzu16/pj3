package com.tracker.expense.dto;

import com.tracker.expense.model.PaymentMethod;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PaymentMethodResponse {
    private UUID id;
    private String name;
    private boolean archived;
    private Instant createdAt;

    public static PaymentMethodResponse fromEntity(PaymentMethod method) {
        if (method == null) {
            return null;
        }
        return PaymentMethodResponse.builder()
                .id(method.getId())
                .name(method.getName())
                .archived(method.isArchived())
                .createdAt(method.getCreatedAt())
                .build();
    }
}
