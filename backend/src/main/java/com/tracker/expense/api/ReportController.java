package com.tracker.expense.api;

import com.tracker.expense.dto.report.CategoryBreakdownResponse;
import com.tracker.expense.dto.report.DailyReportResponse;
import com.tracker.expense.dto.report.MonthlySummaryResponse;
import com.tracker.expense.dto.report.MonthlyTrendResponse;
import com.tracker.expense.dto.report.PaymentMethodBreakdownResponse;
import com.tracker.expense.model.TransactionType;
import com.tracker.expense.security.UserPrincipal;
import com.tracker.expense.service.ReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.time.YearMonth;

@RestController
@RequestMapping("/api/v1/reports")
@RequiredArgsConstructor
public class ReportController {

    private final ReportService reportService;

    @GetMapping("/summary")
    public ResponseEntity<MonthlySummaryResponse> getMonthlySummary(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam(required = false) String month
    ) {
        YearMonth targetMonth = month != null && !month.isBlank()
                ? YearMonth.parse(month)
                : YearMonth.now();

        MonthlySummaryResponse response = reportService.getMonthlySummary(principal.getId(), targetMonth);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/by-category")
    public ResponseEntity<CategoryBreakdownResponse> getCategoryBreakdown(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(defaultValue = "EXPENSE") TransactionType type
    ) {
        CategoryBreakdownResponse response = reportService.getCategoryBreakdown(principal.getId(), from, to, type);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/monthly-trend")
    public ResponseEntity<MonthlyTrendResponse> getMonthlyTrend(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam(defaultValue = "12") int months
    ) {
        MonthlyTrendResponse response = reportService.getMonthlyTrend(principal.getId(), months);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/daily")
    public ResponseEntity<DailyReportResponse> getDailyReport(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam(required = false) String month
    ) {
        YearMonth targetMonth = month != null && !month.isBlank()
                ? YearMonth.parse(month)
                : YearMonth.now();

        DailyReportResponse response = reportService.getDailyReport(principal.getId(), targetMonth);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/by-payment-method")
    public ResponseEntity<PaymentMethodBreakdownResponse> getPaymentMethodBreakdown(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to
    ) {
        PaymentMethodBreakdownResponse response = reportService.getPaymentMethodBreakdown(principal.getId(), from, to);
        return ResponseEntity.ok(response);
    }
}
