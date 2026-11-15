package com.tracker.expense.service;

import com.tracker.expense.common.exception.BadRequestException;
import com.tracker.expense.common.exception.ResourceNotFoundException;
import com.tracker.expense.dto.budget.BudgetResponse;
import com.tracker.expense.dto.budget.CreateBudgetRequest;
import com.tracker.expense.dto.budget.UpdateBudgetRequest;
import com.tracker.expense.model.Budget;
import com.tracker.expense.model.Category;
import com.tracker.expense.model.TransactionType;
import com.tracker.expense.repository.BudgetRepository;
import com.tracker.expense.repository.CategoryRepository;
import com.tracker.expense.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class BudgetService {

    private final BudgetRepository budgetRepository;
    private final CategoryRepository categoryRepository;
    private final TransactionRepository transactionRepository;

    @Transactional(readOnly = true)
    public List<BudgetResponse> getBudgets(UUID userId, YearMonth month) {
        LocalDate monthStart = month.atDay(1);
        LocalDate nextMonthStart = monthStart.plusMonths(1);

        List<Budget> budgets = budgetRepository.findAllByUserIdAndMonth(userId, monthStart);
        if (budgets.isEmpty()) {
            return List.of();
        }

        Set<UUID> categoryIds = budgets.stream()
                .map(Budget::getCategoryId)
                .filter(id -> id != null)
                .collect(Collectors.toSet());

        Map<UUID, Category> categoryMap = categoryRepository.findAllById(categoryIds).stream()
                .filter(c -> c.getUserId().equals(userId))
                .collect(Collectors.toMap(Category::getId, c -> c));

        return budgets.stream()
                .map(b -> mapToBudgetResponse(userId, b, categoryMap.get(b.getCategoryId()), monthStart, nextMonthStart))
                .toList();
    }

    @Transactional(readOnly = true)
    public BudgetResponse getBudgetById(UUID userId, UUID id) {
        Budget budget = budgetRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Budget not found"));

        LocalDate monthStart = budget.getMonth();
        LocalDate nextMonthStart = monthStart.plusMonths(1);

        Category category = budget.getCategoryId() != null
                ? categoryRepository.findByIdAndUserId(budget.getCategoryId(), userId).orElse(null)
                : null;

        return mapToBudgetResponse(userId, budget, category, monthStart, nextMonthStart);
    }

    @Transactional
    public BudgetResponse createBudget(UUID userId, CreateBudgetRequest request) {
        LocalDate monthStart = request.getMonth().withDayOfMonth(1);

        Category category = null;
        if (request.getCategoryId() != null) {
            category = categoryRepository.findByIdAndUserId(request.getCategoryId(), userId)
                    .orElseThrow(() -> new ResourceNotFoundException("Category not found"));

            if (category.getType() != TransactionType.EXPENSE) {
                throw new BadRequestException("Budgets can only be set for expense categories");
            }

            if (budgetRepository.findByUserIdAndCategoryIdAndMonth(userId, category.getId(), monthStart).isPresent()) {
                throw new BadRequestException("Budget already exists for category '" + category.getName() + "' in " + monthStart.toString().substring(0, 7));
            }
        } else {
            if (budgetRepository.findByUserIdAndCategoryIdIsNullAndMonth(userId, monthStart).isPresent()) {
                throw new BadRequestException("Overall monthly budget already exists for " + monthStart.toString().substring(0, 7));
            }
        }

        Budget budget = Budget.builder()
                .userId(userId)
                .categoryId(request.getCategoryId())
                .month(monthStart)
                .amountLimit(request.getAmountLimit())
                .alertThreshold(request.getAlertThreshold())
                .build();

        budget = budgetRepository.save(budget);

        LocalDate nextMonthStart = monthStart.plusMonths(1);
        return mapToBudgetResponse(userId, budget, category, monthStart, nextMonthStart);
    }

    @Transactional
    public BudgetResponse updateBudget(UUID userId, UUID id, UpdateBudgetRequest request) {
        Budget budget = budgetRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Budget not found"));

        if (request.getAmountLimit() != null) {
            budget.setAmountLimit(request.getAmountLimit());
        }
        if (request.getAlertThreshold() != null) {
            budget.setAlertThreshold(request.getAlertThreshold());
        }

        budget = budgetRepository.save(budget);

        LocalDate monthStart = budget.getMonth();
        LocalDate nextMonthStart = monthStart.plusMonths(1);
        Category category = budget.getCategoryId() != null
                ? categoryRepository.findByIdAndUserId(budget.getCategoryId(), userId).orElse(null)
                : null;

        return mapToBudgetResponse(userId, budget, category, monthStart, nextMonthStart);
    }

    @Transactional
    public void deleteBudget(UUID userId, UUID id) {
        Budget budget = budgetRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Budget not found"));
        budgetRepository.delete(budget);
    }

    @Transactional
    public List<BudgetResponse> copyBudgets(UUID userId, YearMonth fromMonth, YearMonth toMonth) {
        LocalDate fromStart = fromMonth.atDay(1);
        LocalDate toStart = toMonth.atDay(1);

        List<Budget> sourceBudgets = budgetRepository.findAllByUserIdAndMonth(userId, fromStart);
        if (sourceBudgets.isEmpty()) {
            return List.of();
        }

        List<Budget> createdBudgets = new ArrayList<>();
        for (Budget source : sourceBudgets) {
            boolean exists = source.getCategoryId() != null
                    ? budgetRepository.findByUserIdAndCategoryIdAndMonth(userId, source.getCategoryId(), toStart).isPresent()
                    : budgetRepository.findByUserIdAndCategoryIdIsNullAndMonth(userId, toStart).isPresent();

            if (!exists) {
                Budget newBudget = Budget.builder()
                        .userId(userId)
                        .categoryId(source.getCategoryId())
                        .month(toStart)
                        .amountLimit(source.getAmountLimit())
                        .alertThreshold(source.getAlertThreshold())
                        .build();
                createdBudgets.add(newBudget);
            }
        }

        if (!createdBudgets.isEmpty()) {
            budgetRepository.saveAll(createdBudgets);
        }

        return getBudgets(userId, toMonth);
    }

    private BudgetResponse mapToBudgetResponse(
            UUID userId,
            Budget budget,
            Category category,
            LocalDate monthStart,
            LocalDate nextMonthStart
    ) {
        BigDecimal spent = budget.getCategoryId() != null
                ? transactionRepository.sumExpenseForCategoryBetween(userId, budget.getCategoryId(), monthStart, nextMonthStart)
                : transactionRepository.sumExpenseBetween(userId, monthStart, nextMonthStart);

        BigDecimal limit = budget.getAmountLimit();
        BigDecimal remaining = limit.subtract(spent);

        BigDecimal percent = limit.compareTo(BigDecimal.ZERO) > 0
                ? spent.multiply(BigDecimal.valueOf(100)).divide(limit, 1, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        String status;
        if (spent.compareTo(limit) > 0) {
            status = "exceeded";
        } else if (percent.compareTo(BigDecimal.valueOf(budget.getAlertThreshold())) >= 0) {
            status = "warning";
        } else {
            status = "safe";
        }

        String catName = category != null ? category.getName() : "Tổng ngân sách tháng";
        String catColor = category != null ? category.getColor() : "#2196F3";

        return BudgetResponse.builder()
                .id(budget.getId())
                .categoryId(budget.getCategoryId())
                .categoryName(catName)
                .categoryColor(catColor)
                .month(budget.getMonth())
                .amountLimit(limit)
                .spent(spent)
                .remaining(remaining)
                .percent(percent)
                .status(status)
                .alertThreshold(budget.getAlertThreshold())
                .createdAt(budget.getCreatedAt())
                .build();
    }
}
