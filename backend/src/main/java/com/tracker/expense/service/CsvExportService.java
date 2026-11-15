package com.tracker.expense.service;

import com.tracker.expense.dto.TransactionResponse;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.io.Writer;
import java.util.List;

@Service
public class CsvExportService {

    public void writeTransactionsCsv(List<TransactionResponse> transactions, Writer writer) throws IOException {
        // 1. Write UTF-8 BOM for Microsoft Excel compatibility with Vietnamese diacritics
        writer.write('\uFEFF');

        // 2. CSV Header
        writer.write("ID,Loại,Số tiền,Ngày giao dịch,Danh mục,Phương thức thanh toán,Ghi chú\r\n");

        // 3. Rows
        for (TransactionResponse txn : transactions) {
            String id = escapeCsv(txn.getId().toString());
            String type = escapeCsv(txn.getType().getValue());
            String amount = escapeCsv(txn.getAmount().toPlainString());
            String date = escapeCsv(txn.getTxnDate().toString());
            String category = escapeCsv(txn.getCategory() != null ? txn.getCategory().getName() : "");
            String paymentMethod = escapeCsv(txn.getPaymentMethod() != null ? txn.getPaymentMethod().getName() : "");
            String note = escapeCsv(txn.getNote() != null ? txn.getNote() : "");

            writer.write(String.format("%s,%s,%s,%s,%s,%s,%s\r\n",
                    id, type, amount, date, category, paymentMethod, note));
        }

        writer.flush();
    }

    private String escapeCsv(String value) {
        if (value == null || value.isEmpty()) {
            return "";
        }

        // CSV Injection prevention: if value starts with formula characters, prefix with single quote
        String sanitized = value;
        char firstChar = sanitized.charAt(0);
        if (firstChar == '=' || firstChar == '+' || firstChar == '-' || firstChar == '@') {
            sanitized = "'" + sanitized;
        }

        // Check if value contains special characters requiring quotes
        boolean containsSpecialChar = sanitized.contains(",")
                || sanitized.contains("\"")
                || sanitized.contains("\n")
                || sanitized.contains("\r");

        if (containsSpecialChar) {
            sanitized = sanitized.replace("\"", "\"\"");
            return "\"" + sanitized + "\"";
        }

        return sanitized;
    }
}
