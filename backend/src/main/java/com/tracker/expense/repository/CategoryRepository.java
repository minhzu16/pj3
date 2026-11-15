package com.tracker.expense.repository;

import com.tracker.expense.model.Category;
import com.tracker.expense.model.TransactionType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CategoryRepository extends JpaRepository<Category, UUID> {
    List<Category> findAllByUserIdAndArchivedFalse(UUID userId);
    List<Category> findAllByUserIdAndTypeAndArchivedFalse(UUID userId, TransactionType type);
    Optional<Category> findByIdAndUserId(UUID id, UUID userId);
    boolean existsByUserIdAndNameIgnoreCaseAndType(UUID userId, String name, TransactionType type);
}
