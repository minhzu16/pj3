package com.tracker.expense.service;

import com.tracker.expense.common.exception.BadRequestException;
import com.tracker.expense.common.exception.ResourceNotFoundException;
import com.tracker.expense.dto.BudgetAlertDto;
import com.tracker.expense.dto.CategoryResponse;
import com.tracker.expense.dto.CreateTransactionRequest;
import com.tracker.expense.dto.PagedTransactionResponse;
import com.tracker.expense.dto.PaymentMethodResponse;
import com.tracker.expense.dto.TransactionFilterRequest;
import com.tracker.expense.dto.TransactionResponse;
import com.tracker.expense.dto.TransactionTotals;
import com.tracker.expense.dto.TransactionWithAlertsResponse;
import com.tracker.expense.dto.UpdateTransactionRequest;
import com.tracker.expense.model.Budget;
import com.tracker.expense.model.Category;
import com.tracker.expense.model.PaymentMethod;
import com.tracker.expense.model.Transaction;
import com.tracker.expense.model.TransactionType;
import com.tracker.expense.repository.BudgetRepository;
import com.tracker.expense.repository.CategoryRepository;
import com.tracker.expense.repository.PaymentMethodRepository;
import com.tracker.expense.repository.TransactionRepository;
import com.tracker.expense.repository.specification.TransactionSpecification;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.Tuple;
import jakarta.persistence.criteria.CriteriaBuilder;
import jakarta.persistence.criteria.CriteriaQuery;
import jakarta.persistence.criteria.Expression;
import jakarta.persistence.criteria.Predicate;
import jakarta.persistence.criteria.Root;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class TransactionService {

    private final TransactionRepository transactionRepository;
    private final CategoryRepository categoryRepository;
    private final PaymentMethodRepository paymentMethodRepository;
    private final BudgetRepository budgetRepository;

    @PersistenceContext
    private EntityManager entityManager;

    @Transactional
    public TransactionWithAlertsResponse createTransaction(UUID userId, CreateTransactionRequest request) {
        Category category = categoryRepository.findByIdAndUserId(request.getCategoryId(), userId)
                .orElseThrow(() -> new ResourceNotFoundException("Category not found"));

        if (category.getType() != request.getType()) {
            throw new BadRequestException("Category type (" + category.getType().getValue() + ") does not match transaction type (" + request.getType().getValue() + ")");
        }

        PaymentMethod paymentMethod = null;
        if (request.getPaymentMethodId() != null) {
            paymentMethod = paymentMethodRepository.findByIdAndUserId(request.getPaymentMethodId(), userId)
                    .orElseThrow(() -> new ResourceNotFoundException("Payment method not found"));
        }

        Transaction transaction = Transaction.builder()
                .userId(userId)
                .type(request.getType())
                .amount(request.getAmount())
                .txnDate(request.getTxnDate())
                .categoryId(category.getId())
                .paymentMethodId(paymentMethod != null ? paymentMethod.getId() : null)
                .note(request.getNote() != null ? request.getNote().trim() : null)
                .build();

        transaction = transactionRepository.save(transaction);

        // Calculate budget alerts for expenses
        List<BudgetAlertDto> budgetAlerts = new ArrayList<>();
        if (request.getType() == TransactionType.EXPENSE) {
            LocalDate monthStart = request.getTxnDate().withDayOfMonth(1);
            LocalDate nextMonthStart = monthStart.plusMonths(1);

            // 1. Category-specific budget check
            budgetRepository.findByUserIdAndCategoryIdAndMonth(userId, category.getId(), monthStart)
                    .ifPresent(budget -> {
                        BudgetAlertDto alert = evaluateBudgetAlert(userId, budget, category.getName(), monthStart, nextMonthStart, true);
                        if (alert != null) {
                            budgetAlerts.add(alert);
                        }
                    });

            // 2. Overall monthly budget check
            budgetRepository.findByUserIdAndCategoryIdIsNullAndMonth(userId, monthStart)
                    .ifPresent(budget -> {
                        BudgetAlertDto alert = evaluateBudgetAlert(userId, budget, "Tổng ngân sách tháng", monthStart, nextMonthStart, false);
                        if (alert != null) {
                            budgetAlerts.add(alert);
                        }
                    });
        }

        TransactionResponse response = TransactionResponse.fromEntity(
                transaction,
                CategoryResponse.fromEntity(category),
                PaymentMethodResponse.fromEntity(paymentMethod)
        );

        return TransactionWithAlertsResponse.builder()
                .transaction(response)
                .budgetAlerts(budgetAlerts)
                .build();
    }

    @Transactional(readOnly = true)
    public TransactionResponse getTransactionById(UUID userId, UUID id) {
        Transaction txn = transactionRepository.findByIdAndUserIdAndDeletedAtIsNull(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Transaction not found"));

        Category category = categoryRepository.findByIdAndUserId(txn.getCategoryId(), userId).orElse(null);
        PaymentMethod paymentMethod = txn.getPaymentMethodId() != null
                ? paymentMethodRepository.findByIdAndUserId(txn.getPaymentMethodId(), userId).orElse(null)
                : null;

        return TransactionResponse.fromEntity(
                txn,
                CategoryResponse.fromEntity(category),
                PaymentMethodResponse.fromEntity(paymentMethod)
        );
    }

    @Transactional
    public TransactionResponse updateTransaction(UUID userId, UUID id, UpdateTransactionRequest request) {
        Transaction txn = transactionRepository.findByIdAndUserIdAndDeletedAtIsNull(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Transaction not found"));

        if (request.getType() != null) {
            txn.setType(request.getType());
        }

        if (request.getCategoryId() != null) {
            Category category = categoryRepository.findByIdAndUserId(request.getCategoryId(), userId)
                    .orElseThrow(() -> new ResourceNotFoundException("Category not found"));
            if (category.getType() != txn.getType()) {
                throw new BadRequestException("Category type does not match transaction type");
            }
            txn.setCategoryId(category.getId());
        }

        if (request.getPaymentMethodId() != null) {
            PaymentMethod method = paymentMethodRepository.findByIdAndUserId(request.getPaymentMethodId(), userId)
                    .orElseThrow(() -> new ResourceNotFoundException("Payment method not found"));
            txn.setPaymentMethodId(method.getId());
        }

        if (request.getAmount() != null) {
            txn.setAmount(request.getAmount());
        }

        if (request.getTxnDate() != null) {
            txn.setTxnDate(request.getTxnDate());
        }

        if (request.getNote() != null) {
            txn.setNote(request.getNote().trim());
        }

        txn = transactionRepository.save(txn);

        Category category = categoryRepository.findByIdAndUserId(txn.getCategoryId(), userId).orElse(null);
        PaymentMethod paymentMethod = txn.getPaymentMethodId() != null
                ? paymentMethodRepository.findByIdAndUserId(txn.getPaymentMethodId(), userId).orElse(null)
                : null;

        return TransactionResponse.fromEntity(
                txn,
                CategoryResponse.fromEntity(category),
                PaymentMethodResponse.fromEntity(paymentMethod)
        );
    }

    @Transactional
    public void deleteTransaction(UUID userId, UUID id) {
        Transaction txn = transactionRepository.findByIdAndUserIdAndDeletedAtIsNull(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Transaction not found"));
        txn.setDeletedAt(Instant.now());
        transactionRepository.save(txn);
    }

    @Transactional(readOnly = true)
    public PagedTransactionResponse getTransactions(UUID userId, TransactionFilterRequest filter) {
        int page = Math.max(filter.getPage(), 1);
        int pageSize = Math.min(Math.max(filter.getPageSize(), 1), 100);

        String sortBy = switch (filter.getSortBy() != null ? filter.getSortBy() : "txnDate") {
            case "amount" -> "amount";
            case "createdAt" -> "createdAt";
            default -> "txnDate";
        };

        Sort.Direction direction = "ASC".equalsIgnoreCase(filter.getSortDirection())
                ? Sort.Direction.ASC
                : Sort.Direction.DESC;

        Pageable pageable = PageRequest.of(page - 1, pageSize, Sort.by(direction, sortBy));
        Specification<Transaction> spec = TransactionSpecification.build(userId, filter);

        Page<Transaction> pagedResult = transactionRepository.findAll(spec, pageable);
        List<TransactionResponse> itemResponses = mapToTransactionResponses(userId, pagedResult.getContent());

        TransactionTotals totals = calculateTotals(userId, filter);

        return PagedTransactionResponse.builder()
                .items(itemResponses)
                .page(page)
                .pageSize(pageSize)
                .total(pagedResult.getTotalElements())
                .totals(totals)
                .build();
    }

    @Transactional(readOnly = true)
    public List<TransactionResponse> getAllFilteredTransactions(UUID userId, TransactionFilterRequest filter) {
        Specification<Transaction> spec = TransactionSpecification.build(userId, filter);
        Sort sort = Sort.by(Sort.Direction.DESC, "txnDate");
        List<Transaction> transactions = transactionRepository.findAll(spec, sort);
        return mapToTransactionResponses(userId, transactions);
    }

    private List<TransactionResponse> mapToTransactionResponses(UUID userId, List<Transaction> transactions) {
        if (transactions.isEmpty()) {
            return List.of();
        }

        Set<UUID> categoryIds = transactions.stream()
                .map(Transaction::getCategoryId)
                .collect(Collectors.toSet());

        Set<UUID> paymentMethodIds = transactions.stream()
                .map(Transaction::getPaymentMethodId)
                .filter(id -> id != null)
                .collect(Collectors.toSet());

        Map<UUID, CategoryResponse> categoryMap = categoryRepository.findAllById(categoryIds).stream()
                .filter(c -> c.getUserId().equals(userId))
                .map(CategoryResponse::fromEntity)
                .collect(Collectors.toMap(CategoryResponse::getId, Function.identity()));

        Map<UUID, PaymentMethodResponse> paymentMethodMap = paymentMethodRepository.findAllById(paymentMethodIds).stream()
                .filter(p -> p.getUserId().equals(userId))
                .map(PaymentMethodResponse::fromEntity)
                .collect(Collectors.toMap(PaymentMethodResponse::getId, Function.identity()));

        return transactions.stream()
                .map(t -> TransactionResponse.fromEntity(
                        t,
                        categoryMap.get(t.getCategoryId()),
                        paymentMethodMap.get(t.getPaymentMethodId())
                ))
                .toList();
    }

    public TransactionTotals calculateTotals(UUID userId, TransactionFilterRequest filter) {
        CriteriaBuilder cb = entityManager.getCriteriaBuilder();
        CriteriaQuery<Tuple> cq = cb.createTupleQuery();
        Root<Transaction> root = cq.from(Transaction.class);

        Specification<Transaction> spec = TransactionSpecification.build(userId, filter);
        Predicate predicate = spec.toPredicate(root, cq, cb);
        if (predicate != null) {
            cq.where(predicate);
        }

        Expression<BigDecimal> incomeCase = cb.<BigDecimal>selectCase()
                .when(cb.equal(root.get("type"), TransactionType.INCOME), root.get("amount"))
                .otherwise(BigDecimal.ZERO);

        Expression<BigDecimal> expenseCase = cb.<BigDecimal>selectCase()
                .when(cb.equal(root.get("type"), TransactionType.EXPENSE), root.get("amount"))
                .otherwise(BigDecimal.ZERO);

        cq.multiselect(
                cb.coalesce(cb.sum(incomeCase), BigDecimal.ZERO),
                cb.coalesce(cb.sum(expenseCase), BigDecimal.ZERO)
        );

        Tuple result = entityManager.createQuery(cq).getSingleResult();
        BigDecimal income = result.get(0, BigDecimal.class);
        BigDecimal expense = result.get(1, BigDecimal.class);

        return TransactionTotals.builder()
                .income(income != null ? income : BigDecimal.ZERO)
                .expense(expense != null ? expense : BigDecimal.ZERO)
                .build();
    }

    private BudgetAlertDto evaluateBudgetAlert(
            UUID userId,
            Budget budget,
            String categoryName,
            LocalDate monthStart,
            LocalDate nextMonthStart,
            boolean isCategorySpecific
    ) {
        BigDecimal spent = isCategorySpecific
                ? transactionRepository.sumExpenseForCategoryBetween(userId, budget.getCategoryId(), monthStart, nextMonthStart)
                : transactionRepository.sumExpenseBetween(userId, monthStart, nextMonthStart);

        BigDecimal limit = budget.getAmountLimit();
        if (limit.compareTo(BigDecimal.ZERO) <= 0) {
            return null;
        }

        BigDecimal percent = spent.multiply(BigDecimal.valueOf(100)).divide(limit, 1, RoundingMode.HALF_UP);

        if (spent.compareTo(limit) > 0) {
            return BudgetAlertDto.builder()
                    .budgetId(budget.getId())
                    .categoryId(budget.getCategoryId())
                    .categoryName(categoryName)
                    .spent(spent)
                    .amountLimit(limit)
                    .percent(percent)
                    .status("exceeded")
                    .message("Ngân sách cho " + categoryName + " đã vượt mức cho phép (" + percent + "%)")
                    .build();
        } else if (percent.compareTo(BigDecimal.valueOf(budget.getAlertThreshold())) >= 0) {
            return BudgetAlertDto.builder()
                    .budgetId(budget.getId())
                    .categoryId(budget.getCategoryId())
                    .categoryName(categoryName)
                    .spent(spent)
                    .amountLimit(limit)
                    .percent(percent)
                    .status("warning")
                    .message("Ngân sách cho " + categoryName + " sắp chạm ngưỡng (" + percent + "%)")
                    .build();
        }

        return null;
    }
}
