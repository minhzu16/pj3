package com.tracker.expense.repository.specification;

import com.tracker.expense.dto.TransactionFilterRequest;
import com.tracker.expense.model.Transaction;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public class TransactionSpecification {

    public static Specification<Transaction> build(UUID userId, TransactionFilterRequest filter) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            // 1. Mandatory Data Isolation: Only own data and not soft-deleted
            predicates.add(cb.equal(root.get("userId"), userId));
            predicates.add(cb.isNull(root.get("deletedAt")));

            if (filter == null) {
                return cb.and(predicates.toArray(new Predicate[0]));
            }

            // 2. Date filters
            if (filter.getFrom() != null) {
                predicates.add(cb.greaterThanOrEqualTo(root.get("txnDate"), filter.getFrom()));
            }
            if (filter.getTo() != null) {
                predicates.add(cb.lessThanOrEqualTo(root.get("txnDate"), filter.getTo()));
            }

            // 3. Type filter
            if (filter.getType() != null) {
                predicates.add(cb.equal(root.get("type"), filter.getType()));
            }

            // 4. Category filter
            if (filter.getCategoryIds() != null && !filter.getCategoryIds().isEmpty()) {
                predicates.add(root.get("categoryId").in(filter.getCategoryIds()));
            }

            // 5. Payment method filter
            if (filter.getPaymentMethodIds() != null && !filter.getPaymentMethodIds().isEmpty()) {
                predicates.add(root.get("paymentMethodId").in(filter.getPaymentMethodIds()));
            }

            // 6. Amount filters
            if (filter.getMinAmount() != null) {
                predicates.add(cb.greaterThanOrEqualTo(root.get("amount"), filter.getMinAmount()));
            }
            if (filter.getMaxAmount() != null) {
                predicates.add(cb.lessThanOrEqualTo(root.get("amount"), filter.getMaxAmount()));
            }

            // 7. Search query in note (case-insensitive)
            if (filter.getQ() != null && !filter.getQ().isBlank()) {
                String searchPattern = "%" + filter.getQ().trim().toLowerCase() + "%";
                predicates.add(cb.like(cb.lower(root.get("note")), searchPattern));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }
}
