package com.tracker.expense.service;

import com.tracker.expense.dto.CategoryResponse;
import com.tracker.expense.dto.PaymentMethodResponse;
import com.tracker.expense.dto.TransactionResponse;
import com.tracker.expense.model.TransactionType;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.StringWriter;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class CsvExportServiceTest {

    private CsvExportService csvExportService;

    @BeforeEach
    void setUp() {
        csvExportService = new CsvExportService();
    }

    @Test
    void writeTransactionsCsv_shouldIncludeUtf8BomAndSanitizeFormulas() throws IOException {
        TransactionResponse txn1 = TransactionResponse.builder()
                .id(UUID.fromString("11111111-1111-1111-1111-111111111111"))
                .type(TransactionType.EXPENSE)
                .amount(new BigDecimal("50000.00"))
                .txnDate(LocalDate.of(2026, 10, 1))
                .category(CategoryResponse.builder().name("Ăn uống, cafe").build())
                .paymentMethod(PaymentMethodResponse.builder().name("Tiền mặt").build())
                .note("=SUM(A1:A10)") // CSV injection attempt
                .build();

        TransactionResponse txn2 = TransactionResponse.builder()
                .id(UUID.fromString("22222222-2222-2222-2222-222222222222"))
                .type(TransactionType.INCOME)
                .amount(new BigDecimal("15000000.00"))
                .txnDate(LocalDate.of(2026, 10, 5))
                .category(CategoryResponse.builder().name("Lương").build())
                .paymentMethod(PaymentMethodResponse.builder().name("Chuyển khoản").build())
                .note("Lương tháng \"10\"")
                .build();

        StringWriter writer = new StringWriter();
        csvExportService.writeTransactionsCsv(List.of(txn1, txn2), writer);

        String output = writer.toString();

        // 1. Verify UTF-8 BOM
        assertTrue(output.startsWith("\uFEFF"), "CSV output must start with UTF-8 BOM");

        // 2. Verify Headers
        assertTrue(output.contains("ID,Loại,Số tiền,Ngày giao dịch,Danh mục,Phương thức thanh toán,Ghi chú"));

        // 3. Verify CSV injection protection (formula starting with '=' must be prefixed with single quote)
        assertTrue(output.contains("'=SUM(A1:A10)"), "Formula injection must be safely escaped");

        // 4. Verify comma escaping in category name
        assertTrue(output.contains("\"Ăn uống, cafe\""), "Fields with commas must be wrapped in double quotes");

        // 5. Verify double-quote escaping
        assertTrue(output.contains("\"Lương tháng \"\"10\"\"\""), "Quotes inside fields must be doubled");
    }
}
