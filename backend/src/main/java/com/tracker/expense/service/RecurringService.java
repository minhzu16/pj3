package com.tracker.expense.service;

import com.tracker.expense.common.exception.BadRequestException;
import com.tracker.expense.common.exception.ResourceNotFoundException;
import com.tracker.expense.dto.CategoryResponse;
import com.tracker.expense.dto.PaymentMethodResponse;
import com.tracker.expense.dto.recurring.CreateRecurringRuleRequest;
import com.tracker.expense.dto.recurring.RecurringRuleResponse;
import com.tracker.expense.dto.recurring.UpcomingRecurringItem;
import com.tracker.expense.dto.recurring.UpdateRecurringRuleRequest;
import com.tracker.expense.model.Category;
import com.tracker.expense.model.PaymentMethod;
import com.tracker.expense.model.RecurringRule;
import com.tracker.expense.model.Transaction;
import com.tracker.expense.repository.CategoryRepository;
import com.tracker.expense.repository.PaymentMethodRepository;
import com.tracker.expense.repository.RecurringRuleRepository;
import com.tracker.expense.repository.TransactionRepository;
import com.tracker.expense.service.recurring.RecurringCalculator;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class RecurringService {

    private final RecurringRuleRepository recurringRuleRepository;
    private final CategoryRepository categoryRepository;
    private final PaymentMethodRepository paymentMethodRepository;
    private final TransactionRepository transactionRepository;

    @Transactional(readOnly = true)
    public List<RecurringRuleResponse> getRules(UUID userId) {
        List<RecurringRule> rules = recurringRuleRepository.findAllByUserId(userId);
        return mapToResponses(userId, rules);
    }

    @Transactional(readOnly = true)
    public RecurringRuleResponse getRuleById(UUID userId, UUID id) {
        RecurringRule rule = recurringRuleRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Recurring rule not found"));

        Category category = categoryRepository.findByIdAndUserId(rule.getCategoryId(), userId).orElse(null);
        PaymentMethod paymentMethod = rule.getPaymentMethodId() != null
                ? paymentMethodRepository.findByIdAndUserId(rule.getPaymentMethodId(), userId).orElse(null)
                : null;

        return RecurringRuleResponse.fromEntity(
                rule,
                CategoryResponse.fromEntity(category),
                PaymentMethodResponse.fromEntity(paymentMethod)
        );
    }

    @Transactional
    public RecurringRuleResponse createRule(UUID userId, CreateRecurringRuleRequest request) {
        Category category = categoryRepository.findByIdAndUserId(request.getCategoryId(), userId)
                .orElseThrow(() -> new ResourceNotFoundException("Category not found"));

        if (category.getType() != request.getType()) {
            throw new BadRequestException("Category type does not match transaction type");
        }

        PaymentMethod paymentMethod = null;
        if (request.getPaymentMethodId() != null) {
            paymentMethod = paymentMethodRepository.findByIdAndUserId(request.getPaymentMethodId(), userId)
                    .orElseThrow(() -> new ResourceNotFoundException("Payment method not found"));
        }

        if (request.getEndDate() != null && request.getEndDate().isBefore(request.getStartDate())) {
            throw new BadRequestException("End date cannot be before start date");
        }

        RecurringRule rule = RecurringRule.builder()
                .userId(userId)
                .type(request.getType())
                .amount(request.getAmount())
                .categoryId(category.getId())
                .paymentMethodId(paymentMethod != null ? paymentMethod.getId() : null)
                .note(request.getNote() != null ? request.getNote().trim() : null)
                .frequency(request.getFrequency())
                .intervalCount(request.getIntervalCount())
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .nextRunDate(request.getStartDate())
                .isActive(true)
                .build();

        rule = recurringRuleRepository.save(rule);

        return RecurringRuleResponse.fromEntity(
                rule,
                CategoryResponse.fromEntity(category),
                PaymentMethodResponse.fromEntity(paymentMethod)
        );
    }

    @Transactional
    public RecurringRuleResponse updateRule(UUID userId, UUID id, UpdateRecurringRuleRequest request) {
        RecurringRule rule = recurringRuleRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Recurring rule not found"));

        if (request.getType() != null) {
            rule.setType(request.getType());
        }

        if (request.getCategoryId() != null) {
            Category category = categoryRepository.findByIdAndUserId(request.getCategoryId(), userId)
                    .orElseThrow(() -> new ResourceNotFoundException("Category not found"));
            if (category.getType() != rule.getType()) {
                throw new BadRequestException("Category type does not match transaction type");
            }
            rule.setCategoryId(category.getId());
        }

        if (request.getPaymentMethodId() != null) {
            PaymentMethod method = paymentMethodRepository.findByIdAndUserId(request.getPaymentMethodId(), userId)
                    .orElseThrow(() -> new ResourceNotFoundException("Payment method not found"));
            rule.setPaymentMethodId(method.getId());
        }

        if (request.getAmount() != null) {
            rule.setAmount(request.getAmount());
        }
        if (request.getNote() != null) {
            rule.setNote(request.getNote().trim());
        }
        if (request.getFrequency() != null) {
            rule.setFrequency(request.getFrequency());
        }
        if (request.getIntervalCount() != null) {
            rule.setIntervalCount(request.getIntervalCount());
        }
        if (request.getEndDate() != null) {
            rule.setEndDate(request.getEndDate());
        }
        if (request.getIsActive() != null) {
            rule.setActive(request.getIsActive());
        }

        rule = recurringRuleRepository.save(rule);

        Category category = categoryRepository.findByIdAndUserId(rule.getCategoryId(), userId).orElse(null);
        PaymentMethod paymentMethod = rule.getPaymentMethodId() != null
                ? paymentMethodRepository.findByIdAndUserId(rule.getPaymentMethodId(), userId).orElse(null)
                : null;

        return RecurringRuleResponse.fromEntity(
                rule,
                CategoryResponse.fromEntity(category),
                PaymentMethodResponse.fromEntity(paymentMethod)
        );
    }

    @Transactional
    public RecurringRuleResponse toggleStatus(UUID userId, UUID id, boolean isActive) {
        RecurringRule rule = recurringRuleRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Recurring rule not found"));
        rule.setActive(isActive);
        rule = recurringRuleRepository.save(rule);

        Category category = categoryRepository.findByIdAndUserId(rule.getCategoryId(), userId).orElse(null);
        PaymentMethod paymentMethod = rule.getPaymentMethodId() != null
                ? paymentMethodRepository.findByIdAndUserId(rule.getPaymentMethodId(), userId).orElse(null)
                : null;

        return RecurringRuleResponse.fromEntity(
                rule,
                CategoryResponse.fromEntity(category),
                PaymentMethodResponse.fromEntity(paymentMethod)
        );
    }

    @Transactional
    public void deleteRule(UUID userId, UUID id) {
        RecurringRule rule = recurringRuleRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Recurring rule not found"));
        rule.setActive(false);
        recurringRuleRepository.delete(rule);
    }

    @Transactional
    public int processRecurringRules(LocalDate today) {
        List<RecurringRule> dueRules = recurringRuleRepository.findAllByIsActiveTrueAndNextRunDateLessThanEqual(today);
        int generatedCount = 0;

        for (RecurringRule rule : dueRules) {
            LocalDate cursor = rule.getNextRunDate();

            while (!cursor.isAfter(today) && (rule.getEndDate() == null || !cursor.isAfter(rule.getEndDate()))) {
                if (!transactionRepository.existsByRecurringRuleIdAndOccurrenceDate(rule.getId(), cursor)) {
                    Transaction txn = Transaction.builder()
                            .userId(rule.getUserId())
                            .type(rule.getType())
                            .amount(rule.getAmount())
                            .txnDate(cursor)
                            .categoryId(rule.getCategoryId())
                            .paymentMethodId(rule.getPaymentMethodId())
                            .note(rule.getNote())
                            .recurringRuleId(rule.getId())
                            .occurrenceDate(cursor)
                            .build();

                    transactionRepository.save(txn);
                    generatedCount++;
                }

                cursor = RecurringCalculator.calculateNextRunDate(rule, cursor);
            }

            rule.setNextRunDate(cursor);
            if (rule.getEndDate() != null && cursor.isAfter(rule.getEndDate())) {
                rule.setActive(false);
            }
            recurringRuleRepository.save(rule);
        }

        log.info("Processed {} recurring rules, generated {} transactions for date {}", dueRules.size(), generatedCount, today);
        return generatedCount;
    }

    @Transactional(readOnly = true)
    public List<UpcomingRecurringItem> getUpcoming(UUID userId, int days) {
        int clampedDays = Math.min(Math.max(days, 1), 90);
        LocalDate today = LocalDate.now();
        LocalDate maxDate = today.plusDays(clampedDays);

        List<RecurringRule> activeRules = recurringRuleRepository.findAllByUserId(userId).stream()
                .filter(RecurringRule::isActive)
                .toList();

        if (activeRules.isEmpty()) {
            return List.of();
        }

        Set<UUID> categoryIds = activeRules.stream().map(RecurringRule::getCategoryId).collect(Collectors.toSet());
        Set<UUID> methodIds = activeRules.stream().map(RecurringRule::getPaymentMethodId).filter(id -> id != null).collect(Collectors.toSet());

        Map<UUID, Category> categoryMap = categoryRepository.findAllById(categoryIds).stream()
                .filter(c -> c.getUserId().equals(userId))
                .collect(Collectors.toMap(Category::getId, c -> c));

        Map<UUID, PaymentMethod> methodMap = paymentMethodRepository.findAllById(methodIds).stream()
                .filter(p -> p.getUserId().equals(userId))
                .collect(Collectors.toMap(PaymentMethod::getId, p -> p));

        List<UpcomingRecurringItem> items = new ArrayList<>();
        for (RecurringRule rule : activeRules) {
            LocalDate cursor = rule.getNextRunDate();
            while (!cursor.isAfter(maxDate) && (rule.getEndDate() == null || !cursor.isAfter(rule.getEndDate()))) {
                if (!cursor.isBefore(today)) {
                    Category cat = categoryMap.get(rule.getCategoryId());
                    PaymentMethod method = rule.getPaymentMethodId() != null ? methodMap.get(rule.getPaymentMethodId()) : null;

                    items.add(UpcomingRecurringItem.builder()
                            .ruleId(rule.getId())
                            .type(rule.getType())
                            .amount(rule.getAmount())
                            .categoryName(cat != null ? cat.getName() : "Không xác định")
                            .categoryColor(cat != null ? cat.getColor() : "#9E9E9E")
                            .paymentMethodName(method != null ? method.getName() : null)
                            .note(rule.getNote())
                            .dueDate(cursor)
                            .build());
                }
                cursor = RecurringCalculator.calculateNextRunDate(rule, cursor);
            }
        }

        items.sort((a, b) -> a.getDueDate().compareTo(b.getDueDate()));
        return items;
    }

    private List<RecurringRuleResponse> mapToResponses(UUID userId, List<RecurringRule> rules) {
        if (rules.isEmpty()) {
            return List.of();
        }

        Set<UUID> categoryIds = rules.stream().map(RecurringRule::getCategoryId).collect(Collectors.toSet());
        Set<UUID> methodIds = rules.stream().map(RecurringRule::getPaymentMethodId).filter(id -> id != null).collect(Collectors.toSet());

        Map<UUID, CategoryResponse> categoryMap = categoryRepository.findAllById(categoryIds).stream()
                .filter(c -> c.getUserId().equals(userId))
                .map(CategoryResponse::fromEntity)
                .collect(Collectors.toMap(CategoryResponse::getId, c -> c));

        Map<UUID, PaymentMethodResponse> methodMap = paymentMethodRepository.findAllById(methodIds).stream()
                .filter(p -> p.getUserId().equals(userId))
                .map(PaymentMethodResponse::fromEntity)
                .collect(Collectors.toMap(PaymentMethodResponse::getId, p -> p));

        return rules.stream()
                .map(r -> RecurringRuleResponse.fromEntity(
                        r,
                        categoryMap.get(r.getCategoryId()),
                        methodMap.get(r.getPaymentMethodId())
                ))
                .toList();
    }
}
