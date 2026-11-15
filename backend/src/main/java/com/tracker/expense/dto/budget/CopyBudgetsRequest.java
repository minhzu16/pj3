package com.tracker.expense.dto.budget;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CopyBudgetsRequest {
    @NotBlank(message = "from month is required (YYYY-MM)")
    private String from;

    @NotBlank(message = "to month is required (YYYY-MM)")
    private String to;
}
