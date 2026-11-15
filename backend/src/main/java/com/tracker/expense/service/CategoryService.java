package com.tracker.expense.service;

import com.tracker.expense.common.exception.BadRequestException;
import com.tracker.expense.common.exception.ResourceNotFoundException;
import com.tracker.expense.dto.CategoryResponse;
import com.tracker.expense.dto.CreateCategoryRequest;
import com.tracker.expense.dto.UpdateCategoryRequest;
import com.tracker.expense.model.Category;
import com.tracker.expense.model.TransactionType;
import com.tracker.expense.repository.CategoryRepository;
import com.tracker.expense.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class CategoryService {

    private final CategoryRepository categoryRepository;
    private final TransactionRepository transactionRepository;

    @Transactional(readOnly = true)
    public List<CategoryResponse> getCategories(UUID userId, TransactionType type) {
        List<Category> categories;
        if (type != null) {
            categories = categoryRepository.findAllByUserIdAndTypeAndArchivedFalse(userId, type);
        } else {
            categories = categoryRepository.findAllByUserIdAndArchivedFalse(userId);
        }
        return categories.stream().map(CategoryResponse::fromEntity).toList();
    }

    @Transactional(readOnly = true)
    public CategoryResponse getCategoryById(UUID userId, UUID id) {
        Category category = categoryRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Category not found"));
        return CategoryResponse.fromEntity(category);
    }

    @Transactional
    public CategoryResponse createCategory(UUID userId, CreateCategoryRequest request) {
        String trimmedName = request.getName().trim();

        if (categoryRepository.existsByUserIdAndNameIgnoreCaseAndType(userId, trimmedName, request.getType())) {
            throw new BadRequestException("Category '" + trimmedName + "' already exists for type " + request.getType().getValue());
        }

        Category category = Category.builder()
                .userId(userId)
                .name(trimmedName)
                .type(request.getType())
                .color(request.getColor())
                .icon(request.getIcon())
                .archived(false)
                .build();

        category = categoryRepository.save(category);
        return CategoryResponse.fromEntity(category);
    }

    @Transactional
    public CategoryResponse updateCategory(UUID userId, UUID id, UpdateCategoryRequest request) {
        Category category = categoryRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Category not found"));

        if (request.getName() != null && !request.getName().isBlank()) {
            String newName = request.getName().trim();
            if (!newName.equalsIgnoreCase(category.getName()) &&
                    categoryRepository.existsByUserIdAndNameIgnoreCaseAndType(userId, newName, category.getType())) {
                throw new BadRequestException("Category '" + newName + "' already exists for type " + category.getType().getValue());
            }
            category.setName(newName);
        }

        if (request.getColor() != null) {
            category.setColor(request.getColor());
        }
        if (request.getIcon() != null) {
            category.setIcon(request.getIcon());
        }
        if (request.getArchived() != null) {
            category.setArchived(request.getArchived());
        }

        category = categoryRepository.save(category);
        return CategoryResponse.fromEntity(category);
    }

    @Transactional
    public void deleteCategory(UUID userId, UUID id) {
        Category category = categoryRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Category not found"));

        boolean hasTransactions = transactionRepository.existsByUserIdAndCategoryIdAndDeletedAtIsNull(userId, id);
        if (hasTransactions) {
            category.setArchived(true);
            categoryRepository.save(category);
        } else {
            categoryRepository.delete(category);
        }
    }
}
