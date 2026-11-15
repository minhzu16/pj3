package com.tracker.expense.service;

import com.tracker.expense.dto.report.CategoryBreakdownItem;
import com.tracker.expense.dto.report.CategoryBreakdownResponse;
import com.tracker.expense.dto.report.DailyReportPoint;
import com.tracker.expense.dto.report.DailyReportResponse;
import com.tracker.expense.dto.report.MonthlySummaryResponse;
import com.tracker.expense.dto.report.MonthlyTrendPoint;
import com.tracker.expense.dto.report.MonthlyTrendResponse;
import com.tracker.expense.dto.report.PaymentMethodBreakdownItem;
import com.tracker.expense.dto.report.PaymentMethodBreakdownResponse;
import com.tracker.expense.model.Category;
import com.tracker.expense.model.PaymentMethod;
import com.tracker.expense.model.TransactionType;
import com.tracker.expense.repository.CategoryRepository;
import com.tracker.expense.repository.PaymentMethodRepository;
import com.tracker.expense.repository.TransactionRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.Tuple;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ReportService {

    private final TransactionRepository transactionRepository;
    private final CategoryRepository categoryRepository;
    private final PaymentMethodRepository paymentMethodRepository;

    @PersistenceContext
    private EntityManager entityManager;

    private static final DateTimeFormatter MONTH_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM");

    @Transactional(readOnly = true)
    public MonthlySummaryResponse getMonthlySummary(UUID userId, YearMonth month) {
        LocalDate monthStart = month.atDay(1);
        LocalDate nextMonthStart = monthStart.plusMonths(1);
        LocalDate prevMonthStart = monthStart.minusMonths(1);

        BigDecimal income = transactionRepository.sumIncomeBetween(userId, monthStart, nextMonthStart);
        BigDecimal expense = transactionRepository.sumExpenseBetween(userId, monthStart, nextMonthStart);
        BigDecimal net = income.subtract(expense);

        BigDecimal prevExpense = transactionRepository.sumExpenseBetween(userId, prevMonthStart, monthStart);

        BigDecimal changePercent = null;
        if (prevExpense.compareTo(BigDecimal.ZERO) > 0) {
            changePercent = expense.subtract(prevExpense)
                    .multiply(BigDecimal.valueOf(100))
                    .divide(prevExpense, 1, RoundingMode.HALF_UP);
        }

        return MonthlySummaryResponse.builder()
                .month(month.format(MONTH_FORMATTER))
                .currency("VND")
                .totalIncome(income)
                .totalExpense(expense)
                .net(net)
                .previousMonthExpense(prevExpense)
                .expenseChangePercent(changePercent)
                .build();
    }

    @Transactional(readOnly = true)
    public CategoryBreakdownResponse getCategoryBreakdown(UUID userId, LocalDate from, LocalDate to, TransactionType type) {
        String jpql = """
            SELECT t.categoryId, SUM(t.amount)
            FROM Transaction t
            WHERE t.userId = :userId
              AND t.deletedAt IS NULL
              AND t.type = :type
              AND t.txnDate >= :from
              AND t.txnDate <= :to
            GROUP BY t.categoryId
            ORDER BY SUM(t.amount) DESC
        """;

        List<Tuple> results = entityManager.createQuery(jpql, Tuple.class)
                .setParameter("userId", userId)
                .setParameter("type", type)
                .setParameter("from", from)
                .setParameter("to", to)
                .getResultList();

        if (results.isEmpty()) {
            return CategoryBreakdownResponse.builder()
                    .total(BigDecimal.ZERO)
                    .items(List.of())
                    .build();
        }

        List<UUID> categoryIds = results.stream()
                .map(r -> r.get(0, UUID.class))
                .toList();

        Map<UUID, Category> categoryMap = categoryRepository.findAllById(categoryIds).stream()
                .filter(c -> c.getUserId().equals(userId))
                .collect(Collectors.toMap(Category::getId, c -> c));

        BigDecimal grandTotal = BigDecimal.ZERO;
        List<CategoryBreakdownItem> rawItems = new ArrayList<>();

        for (Tuple row : results) {
            UUID catId = row.get(0, UUID.class);
            BigDecimal total = row.get(1, BigDecimal.class);
            grandTotal = grandTotal.add(total);

            Category cat = categoryMap.get(catId);
            String name = cat != null ? cat.getName() : "Không xác định";
            String color = cat != null ? cat.getColor() : "#9E9E9E";

            rawItems.add(CategoryBreakdownItem.builder()
                    .categoryId(catId)
                    .categoryName(name)
                    .color(color)
                    .total(total)
                    .build());
        }

        final BigDecimal finalGrandTotal = grandTotal;
        List<CategoryBreakdownItem> itemsWithPercent = rawItems.stream()
                .map(item -> {
                    BigDecimal percent = finalGrandTotal.compareTo(BigDecimal.ZERO) > 0
                            ? item.getTotal().multiply(BigDecimal.valueOf(100)).divide(finalGrandTotal, 1, RoundingMode.HALF_UP)
                            : BigDecimal.ZERO;
                    item.setPercent(percent);
                    return item;
                })
                .toList();

        return CategoryBreakdownResponse.builder()
                .total(grandTotal)
                .items(itemsWithPercent)
                .build();
    }

    @Transactional(readOnly = true)
    public MonthlyTrendResponse getMonthlyTrend(UUID userId, int monthsCount) {
        int clampedMonths = Math.min(Math.max(monthsCount, 1), 36);
        YearMonth currentMonth = YearMonth.now();
        YearMonth startMonth = currentMonth.minusMonths(clampedMonths - 1);

        LocalDate startDate = startMonth.atDay(1);
        LocalDate endDate = currentMonth.plusMonths(1).atDay(1);

        String jpql = """
            SELECT FUNCTION('TO_CHAR', t.txnDate, 'YYYY-MM'),
                   COALESCE(SUM(CASE WHEN t.type = com.tracker.expense.model.TransactionType.INCOME THEN t.amount ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN t.type = com.tracker.expense.model.TransactionType.EXPENSE THEN t.amount ELSE 0 END), 0)
            FROM Transaction t
            WHERE t.userId = :userId
              AND t.deletedAt IS NULL
              AND t.txnDate >= :startDate
              AND t.txnDate < :endDate
            GROUP BY FUNCTION('TO_CHAR', t.txnDate, 'YYYY-MM')
        """;

        List<Tuple> results = entityManager.createQuery(jpql, Tuple.class)
                .setParameter("userId", userId)
                .setParameter("startDate", startDate)
                .setParameter("endDate", endDate)
                .getResultList();

        Map<String, MonthlyTrendPoint> dataMap = new HashMap<>();
        for (Tuple row : results) {
            String monthStr = row.get(0, String.class);
            BigDecimal inc = row.get(1, BigDecimal.class);
            BigDecimal exp = row.get(2, BigDecimal.class);
            BigDecimal net = inc.subtract(exp);

            dataMap.put(monthStr, MonthlyTrendPoint.builder()
                    .month(monthStr)
                    .income(inc)
                    .expense(exp)
                    .net(net)
                    .build());
        }

        // Fill empty months with zero as specified in section 8.4
        List<MonthlyTrendPoint> points = new ArrayList<>();
        YearMonth cursor = startMonth;
        while (!cursor.isAfter(currentMonth)) {
            String key = cursor.format(MONTH_FORMATTER);
            MonthlyTrendPoint point = dataMap.getOrDefault(key, MonthlyTrendPoint.builder()
                    .month(key)
                    .income(BigDecimal.ZERO)
                    .expense(BigDecimal.ZERO)
                    .net(BigDecimal.ZERO)
                    .build());
            points.add(point);
            cursor = cursor.plusMonths(1);
        }

        return MonthlyTrendResponse.builder()
                .currency("VND")
                .points(points)
                .build();
    }

    @Transactional(readOnly = true)
    public DailyReportResponse getDailyReport(UUID userId, YearMonth month) {
        LocalDate monthStart = month.atDay(1);
        LocalDate nextMonthStart = monthStart.plusMonths(1);

        String jpql = """
            SELECT t.txnDate,
                   COALESCE(SUM(CASE WHEN t.type = com.tracker.expense.model.TransactionType.INCOME THEN t.amount ELSE 0 END), 0),
                   COALESCE(SUM(CASE WHEN t.type = com.tracker.expense.model.TransactionType.EXPENSE THEN t.amount ELSE 0 END), 0)
            FROM Transaction t
            WHERE t.userId = :userId
              AND t.deletedAt IS NULL
              AND t.txnDate >= :monthStart
              AND t.txnDate < :nextMonthStart
            GROUP BY t.txnDate
        """;

        List<Tuple> results = entityManager.createQuery(jpql, Tuple.class)
                .setParameter("userId", userId)
                .setParameter("monthStart", monthStart)
                .setParameter("nextMonthStart", nextMonthStart)
                .getResultList();

        Map<LocalDate, Tuple> dateMap = results.stream()
                .collect(Collectors.toMap(r -> r.get(0, LocalDate.class), r -> r));

        List<DailyReportPoint> points = new ArrayList<>();
        BigDecimal cumulativeExpense = BigDecimal.ZERO;

        for (int day = 1; day <= month.lengthOfMonth(); day++) {
            LocalDate date = month.atDay(day);
            BigDecimal inc = BigDecimal.ZERO;
            BigDecimal exp = BigDecimal.ZERO;

            if (dateMap.containsKey(date)) {
                Tuple row = dateMap.get(date);
                inc = row.get(1, BigDecimal.class);
                exp = row.get(2, BigDecimal.class);
            }

            cumulativeExpense = cumulativeExpense.add(exp);

            points.add(DailyReportPoint.builder()
                    .date(date)
                    .income(inc)
                    .expense(exp)
                    .cumulativeExpense(cumulativeExpense)
                    .build());
        }

        return DailyReportResponse.builder()
                .month(month.format(MONTH_FORMATTER))
                .points(points)
                .build();
    }

    @Transactional(readOnly = true)
    public PaymentMethodBreakdownResponse getPaymentMethodBreakdown(UUID userId, LocalDate from, LocalDate to) {
        String jpql = """
            SELECT t.paymentMethodId, SUM(t.amount)
            FROM Transaction t
            WHERE t.userId = :userId
              AND t.deletedAt IS NULL
              AND t.type = com.tracker.expense.model.TransactionType.EXPENSE
              AND t.txnDate >= :from
              AND t.txnDate <= :to
            GROUP BY t.paymentMethodId
            ORDER BY SUM(t.amount) DESC
        """;

        List<Tuple> results = entityManager.createQuery(jpql, Tuple.class)
                .setParameter("userId", userId)
                .setParameter("from", from)
                .setParameter("to", to)
                .getResultList();

        if (results.isEmpty()) {
            return PaymentMethodBreakdownResponse.builder()
                    .total(BigDecimal.ZERO)
                    .items(List.of())
                    .build();
        }

        List<UUID> methodIds = results.stream()
                .map(r -> r.get(0, UUID.class))
                .filter(id -> id != null)
                .toList();

        Map<UUID, PaymentMethod> methodMap = paymentMethodRepository.findAllById(methodIds).stream()
                .filter(p -> p.getUserId().equals(userId))
                .collect(Collectors.toMap(PaymentMethod::getId, p -> p));

        BigDecimal grandTotal = BigDecimal.ZERO;
        List<PaymentMethodBreakdownItem> rawItems = new ArrayList<>();

        for (Tuple row : results) {
            UUID methodId = row.get(0, UUID.class);
            BigDecimal total = row.get(1, BigDecimal.class);
            grandTotal = grandTotal.add(total);

            String name = "Chưa phân loại";
            if (methodId != null) {
                PaymentMethod method = methodMap.get(methodId);
                if (method != null) {
                    name = method.getName();
                }
            }

            rawItems.add(PaymentMethodBreakdownItem.builder()
                    .paymentMethodId(methodId)
                    .paymentMethodName(name)
                    .total(total)
                    .build());
        }

        final BigDecimal finalGrandTotal = grandTotal;
        List<PaymentMethodBreakdownItem> itemsWithPercent = rawItems.stream()
                .map(item -> {
                    BigDecimal percent = finalGrandTotal.compareTo(BigDecimal.ZERO) > 0
                            ? item.getTotal().multiply(BigDecimal.valueOf(100)).divide(finalGrandTotal, 1, RoundingMode.HALF_UP)
                            : BigDecimal.ZERO;
                    item.setPercent(percent);
                    return item;
                })
                .toList();

        return PaymentMethodBreakdownResponse.builder()
                .total(grandTotal)
                .items(itemsWithPercent)
                .build();
    }
}
