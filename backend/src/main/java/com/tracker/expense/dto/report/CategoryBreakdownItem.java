package com.tracker.expense.dto.report;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CategoryBreakdownItem {
    private UUID categoryId;
    private String categoryName;
    private String color;
    private BigDecimal total;
    private BigDecimal percent;
}
