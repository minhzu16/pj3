package com.tracker.expense.repository;

import com.tracker.expense.model.Transaction;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface TransactionRepository extends JpaRepository<Transaction, UUID>, JpaSpecificationExecutor<Transaction> {

    Optional<Transaction> findByIdAndUserIdAndDeletedAtIsNull(UUID id, UUID userId);

    @Query("""
        SELECT COALESCE(SUM(t.amount), 0)
        FROM Transaction t
        WHERE t.userId = :userId
          AND t.deletedAt IS NULL
          AND t.type = com.tracker.expense.model.TransactionType.INCOME
          AND t.txnDate >= :startDate
          AND t.txnDate < :endDate
    """)
    BigDecimal sumIncomeBetween(
            @Param("userId") UUID userId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate
    );

    @Query("""
        SELECT COALESCE(SUM(t.amount), 0)
        FROM Transaction t
        WHERE t.userId = :userId
          AND t.deletedAt IS NULL
          AND t.type = com.tracker.expense.model.TransactionType.EXPENSE
          AND t.txnDate >= :startDate
          AND t.txnDate < :endDate
    """)
    BigDecimal sumExpenseBetween(
            @Param("userId") UUID userId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate
    );

    @Query("""
        SELECT COALESCE(SUM(t.amount), 0)
        FROM Transaction t
        WHERE t.userId = :userId
          AND t.deletedAt IS NULL
          AND t.type = com.tracker.expense.model.TransactionType.EXPENSE
          AND t.categoryId = :categoryId
          AND t.txnDate >= :startDate
          AND t.txnDate < :endDate
    """)
    BigDecimal sumExpenseForCategoryBetween(
            @Param("userId") UUID userId,
            @Param("categoryId") UUID categoryId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate
    );

    boolean existsByRecurringRuleIdAndOccurrenceDate(UUID recurringRuleId, LocalDate occurrenceDate);

    boolean existsByUserIdAndCategoryIdAndDeletedAtIsNull(UUID userId, UUID categoryId);

    boolean existsByUserIdAndPaymentMethodIdAndDeletedAtIsNull(UUID userId, UUID paymentMethodId);
}
