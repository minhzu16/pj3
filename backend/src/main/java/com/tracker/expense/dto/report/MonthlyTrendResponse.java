package com.tracker.expense.dto.report;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MonthlyTrendResponse {
    @Builder.Default
    private String currency = "VND";
    private List<MonthlyTrendPoint> points;
}
