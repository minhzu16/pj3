package com.tracker.expense.dto;

import com.tracker.expense.model.Category;
import com.tracker.expense.model.TransactionType;
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
public class CategoryResponse {
    private UUID id;
    private String name;
    private TransactionType type;
    private String color;
    private String icon;
    private boolean archived;
    private Instant createdAt;

    public static CategoryResponse fromEntity(Category category) {
        if (category == null) {
            return null;
        }
        return CategoryResponse.builder()
                .id(category.getId())
                .name(category.getName())
                .type(category.getType())
                .color(category.getColor())
                .icon(category.getIcon())
                .archived(category.isArchived())
                .createdAt(category.getCreatedAt())
                .build();
    }
}
