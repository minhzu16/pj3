package com.tracker.expense.repository;

import com.tracker.expense.model.RecurringRule;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface RecurringRuleRepository extends JpaRepository<RecurringRule, UUID> {
    List<RecurringRule> findAllByUserId(UUID userId);
    Optional<RecurringRule> findByIdAndUserId(UUID id, UUID userId);
    List<RecurringRule> findAllByIsActiveTrueAndNextRunDateLessThanEqual(LocalDate date);
}
