package com.tracker.expense.service;

import com.tracker.expense.common.exception.BadRequestException;
import com.tracker.expense.common.exception.ResourceNotFoundException;
import com.tracker.expense.dto.CategoryResponse;
import com.tracker.expense.dto.CreateCategoryRequest;
import com.tracker.expense.model.Category;
import com.tracker.expense.model.TransactionType;
import com.tracker.expense.repository.CategoryRepository;
import com.tracker.expense.repository.TransactionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CategoryServiceTest {

    @Mock
    private CategoryRepository categoryRepository;

    @Mock
    private TransactionRepository transactionRepository;

    @InjectMocks
    private CategoryService categoryService;

    private final UUID userAId = UUID.randomUUID();
    private final UUID userBId = UUID.randomUUID();
    private final UUID categoryId = UUID.randomUUID();

    private Category sampleCategory;

    @BeforeEach
    void setUp() {
        sampleCategory = Category.builder()
                .id(categoryId)
                .userId(userAId)
                .name("Ăn uống")
                .type(TransactionType.EXPENSE)
                .color("#FF5722")
                .icon("restaurant")
                .archived(false)
                .build();
    }

    @Test
    void createCategory_success() {
        CreateCategoryRequest request = CreateCategoryRequest.builder()
                .name("Ăn uống")
                .type(TransactionType.EXPENSE)
                .color("#FF5722")
                .icon("restaurant")
                .build();

        when(categoryRepository.existsByUserIdAndNameIgnoreCaseAndType(userAId, "Ăn uống", TransactionType.EXPENSE))
                .thenReturn(false);
        when(categoryRepository.save(any(Category.class))).thenReturn(sampleCategory);

        CategoryResponse response = categoryService.createCategory(userAId, request);

        assertNotNull(response);
        assertEquals("Ăn uống", response.getName());
        assertEquals(TransactionType.EXPENSE, response.getType());
    }

    @Test
    void createCategory_duplicateName_shouldThrowBadRequestException() {
        CreateCategoryRequest request = CreateCategoryRequest.builder()
                .name("Ăn uống")
                .type(TransactionType.EXPENSE)
                .build();

        when(categoryRepository.existsByUserIdAndNameIgnoreCaseAndType(userAId, "Ăn uống", TransactionType.EXPENSE))
                .thenReturn(true);

        assertThrows(BadRequestException.class, () -> categoryService.createCategory(userAId, request));
    }

    @Test
    void getCategoryById_belongingToAnotherUser_shouldThrowResourceNotFound_IDORProtection() {
        when(categoryRepository.findByIdAndUserId(categoryId, userBId)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> categoryService.getCategoryById(userBId, categoryId));
    }

    @Test
    void deleteCategory_referencedByTransactions_shouldSoftArchive() {
        when(categoryRepository.findByIdAndUserId(categoryId, userAId)).thenReturn(Optional.of(sampleCategory));
        when(transactionRepository.existsByUserIdAndCategoryIdAndDeletedAtIsNull(userAId, categoryId)).thenReturn(true);

        categoryService.deleteCategory(userAId, categoryId);

        assertTrue(sampleCategory.isArchived());
        verify(categoryRepository).save(sampleCategory);
    }

    @Test
    void deleteCategory_notReferenced_shouldHardDelete() {
        when(categoryRepository.findByIdAndUserId(categoryId, userAId)).thenReturn(Optional.of(sampleCategory));
        when(transactionRepository.existsByUserIdAndCategoryIdAndDeletedAtIsNull(userAId, categoryId)).thenReturn(false);

        categoryService.deleteCategory(userAId, categoryId);

        verify(categoryRepository).delete(sampleCategory);
    }
}
