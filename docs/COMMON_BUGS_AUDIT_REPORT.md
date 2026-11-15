# Báo cáo Kiểm thử & Thẩm định 20 Bugs Phổ biến (Financial Tracker Audit)

> Dự án: **Personal Expense & Budget Tracker**  
> Đối tượng kiểm tra: Hệ thống tính toán tài chính, phân quyền dữ liệu đa người dùng, chu kỳ định kỳ, báo cáo tổng hợp và giao diện người dùng.  
> Bộ test tự động kiểm chứng: [`CommonBugsAuditTest.java`](file:///d:/ky9/self_project/pj3/backend/src/test/java/com/tracker/expense/CommonBugsAuditTest.java) (20/20 Test passed), [`widget_test.dart`](file:///d:/ky9/self_project/pj3/frontend/test/widget_test.dart) (100% passed).

---

## Bảng tổng hợp trạng thái 20 Bugs

| # | Nhóm lỗi / Bug phổ biến | Mức độ nghiêm trọng | Trạng thái dự án | Cơ chế phòng thủ / Giải pháp |
| :--- | :--- | :--- | :--- | :--- |
| **01** | Sai số dấu phẩy động (`double`/`float`) | **CRITICAL** | **ĐÃ GIẢI QUYẾT** | Dùng thuần `BigDecimal(String)` trên Backend và `package:decimal` trên Flutter |
| **02** | Lỗ hổng IDOR xem/sửa dữ liệu người khác | **CRITICAL** | **ĐÃ GIẢI QUYẾT** | Defense-in-Depth: Filter JWT -> Service WHERE `userId` -> DB Composite Keys |
| **03** | Gán danh mục của người khác (FK Poisoning) | **HIGH** | **ĐÃ GIẢI QUYẾT** | Khóa ngoại kép tại DB `(category_id, user_id)` chặn cấp PostgreSQL |
| **04** | Sai lệch mốc thời gian cuối tháng (Microsecond bug) | **MEDIUM** | **ĐÃ GIẢI QUYẾT** | Khoảng nửa mở `[start, nextStart)` (`>= 01` và `< next_month_01`) |
| **05** | Lỗi ngày cuối tháng của lịch định kỳ (Jan 31 bug) | **HIGH** | **ĐÃ GIẢI QUYẾT** | `RecurringCalculator` tự động kẹp ngày (Jan 31 -> Feb 28/29 -> Mar 31) |
| **06** | Chạy lặp giao dịch định kỳ (Duplicate execution) | **HIGH** | **ĐÃ GIẢI QUYẾT** | Khóa `UNIQUE (recurring_rule_id, occurrence_date)` đảm bảo Idempotency |
| **07** | Tràn bộ nhớ (OOM) khi tính tổng trong RAM | **HIGH** | **ĐÃ GIẢI QUYẾT** | Tính toán tổng hợp qua câu lệnh SQL (`SUM()`, `GROUP BY`) tại Database |
| **08** | Lỗi N+1 Query khi tải danh sách giao dịch | **MEDIUM** | **ĐÃ GIẢI QUYẾT** | Sử dụng `@EntityGraph` fetch đồng thời `category` và `paymentMethod` |
| **09** | Tấn công CSV Formula Injection (Excel DDE) | **HIGH** | **ĐÃ GIẢI QUYẾT** | `CsvExportService` tiền tố `'` nếu chuỗi bắt đầu bằng `=`, `+`, `-`, `@` |
| **10** | Lỗi hiển thị tiếng Việt trên Excel (Mojibake) | **LOW** | **ĐÃ GIẢI QUYẾT** | Tự động ghi byte UTF-8 BOM (`\uFEFF`) ở đầu tệp CSV |
| **11** | Lọt dữ liệu đã xóa mềm vào báo cáo (Soft Delete Leak) | **HIGH** | **ĐÃ GIẢI QUYẾT** | Tất cả Criteria Specification & Repository bắt buộc `deleted_at IS NULL` |
| **12** | Lỗi khóa ngoại khi xóa danh mục đã có giao dịch | **MEDIUM** | **ĐÃ GIẢI QUYẾT** | Kiểm tra `hasTransactions`: tự động chuyển sang lưu trữ mềm (`archived=true`) |
| **13** | Lệch loại (Giao dịch Chi tiêu gán vào Danh mục Thu nhập) | **HIGH** | **ĐÃ GIẢI QUYẾT** | Kiểm tra `category.getType() != request.getType()` ném `400 BadRequest` |
| **14** | Mất mốc tháng trong biểu đồ xu hướng 12 tháng | **MEDIUM** | **ĐÃ GIẢI QUYẾT** | Tạo danh sách đủ 12 tháng liên tục và tự động điền `0` (Zero-fill) |
| **15** | Trễ cảnh báo vượt ngân sách khi thêm giao dịch | **MEDIUM** | **ĐÃ GIẢI QUYẾT** | Đánh giá ngân sách tức thì khi tạo giao dịch và trả kèm `budgetAlerts` |
| **16** | Giao dịch số tiền âm hoặc bằng 0 | **HIGH** | **ĐÃ GIẢI QUYẾT** | DTO Validation `@DecimalMin(value = "0.01")` chặn ngay tại Controller |
| **17** | Tranh chấp làm mới token khi hết hạn (Token Race Condition)| **HIGH** | **ĐÃ GIẢI QUYẾT** | Flutter Dio interceptor xếp hàng đợi tự động làm mới qua Refresh Token |
| **18** | Tái sử dụng Refresh Token bị đánh cắp (Token Replay) | **HIGH** | **ĐÃ GIẢI QUYẾT** | Refresh Token Rotation: mỗi Refresh Token chỉ dùng 1 lần và thu hồi phiên cũ |
| **19** | SQL Injection trong ô tìm kiếm (`q`) | **HIGH** | **ĐÃ GIẢI QUYẾT** | JPA Criteria API parameterized expression `cb.like(cb.lower(...))` |
| **20** | Số thập phân lớn bị chuyển thành ký hiệu khoa học (`1E6`) | **MEDIUM** | **ĐÃ GIẢI QUYẾT** | Cấu hình Jackson `write-bigdecimal-as-plain: true` |

---

## Chi tiết phân tích & Bằng chứng thực nghiệm từng Bug

### 1. Sai số dấu phẩy động (Binary Floating-Point Imprecision)
- **Vấn đề:** Trong chuẩn IEEE 754, `double d1 = 0.1; double d2 = 0.2; d1 + d2 == 0.3` trả về `false` (kết quả thực tế là `0.30000000000000004`). Sau hàng ngàn phép cộng trừ thu chi, số dư tài khoản sẽ bị sai lệch đơn vị xu hoặc đồng.
- **Giải pháp:**
  - Backend: Toàn bộ model [`Transaction.java`](file:///d:/ky9/self_project/pj3/backend/src/main/java/com/tracker/expense/model/Transaction.java), [`Budget.java`](file:///d:/ky9/self_project/pj3/backend/src/main/java/com/tracker/expense/model/Budget.java) và DTOs đều sử dụng `java.math.BigDecimal`.
  - Frontend: Sử dụng thư viện `package:decimal` trong [`transaction_model.dart`](file:///d:/ky9/self_project/pj3/frontend/lib/models/transaction_model.dart) và [`budget_model.dart`](file:///d:/ky9/self_project/pj3/frontend/lib/models/budget_model.dart).
- **Test kiểm chứng:** `bug01_floatingPointPrecisionVsBigDecimal` trong [`CommonBugsAuditTest.java`](file:///d:/ky9/self_project/pj3/backend/src/test/java/com/tracker/expense/CommonBugsAuditTest.java).

### 2. Lỗ hổng IDOR (Insecure Direct Object Reference)
- **Vấn đề:** User B thay đổi `id` trên đường dẫn `DELETE /api/v1/transactions/{id}` để xóa trộm giao dịch của User A.
- **Giải pháp 4 lớp bảo vệ (Defense-in-Depth):**
  1. Trích xuất danh tính từ JWT token (không tin cậy bất kỳ thông tin nào từ body/path).
  2. Mọi truy vấn Spring Data JPA đều có tham số bắt buộc `userId`: `findByIdAndUserIdAndDeletedAtIsNull(id, userId)`.
  3. Trả về `404 Not Found` thay vì `403 Forbidden` để kẻ tấn công không thể dò quét sự tồn tại của ID (Resource Enumeration Mitigation).
- **Test kiểm chứng:** `bug02_idorAccessControl_crossUserDenied` (User B nhận 404 khi truy cập dữ liệu User A).

### 3. Gán chéo tài nguyên giữa các người dùng (Foreign Key Poisoning)
- **Vấn đề:** User A tạo giao dịch nhưng truyền `categoryId` thuộc quyền sở hữu của User B.
- **Giải pháp:**
  - Tầng Service: `categoryRepository.findByIdAndUserId(categoryId, userId).orElseThrow(...)`.
  - Tầng Cơ sở dữ liệu: Khóa ngoại kép trong Flyway [`V1__init_schema.sql`](file:///d:/ky9/self_project/pj3/backend/src/main/resources/db/migration/V1__init_schema.sql):
    ```sql
    FOREIGN KEY (category_id, user_id) REFERENCES categories(id, user_id)
    ```
    Nếu có lỗi logic tại code Java thì chính PostgreSQL cũng sẽ từ chối giao dịch.
- **Test kiểm chứng:** `bug03_foreignKeyPoisoning_crossUserCategoryDenied`.

### 4. Lỗi mốc thời gian cuối tháng (Microsecond Boundary Bug)
- **Vấn đề:** Nếu dùng `BETWEEN '2026-10-01' AND '2026-10-31 23:59:59'`, các giao dịch có độ phân giải microsecond (`23:59:59.999999`) sẽ bị bỏ sót.
- **Giải pháp:** Luôn sử dụng khoảng nửa mở `[start, nextStart)`:
  - `start = 2026-10-01`
  - `nextStart = 2026-11-01`
  - Điều kiện SQL: `txn_date >= :start AND txn_date < :nextStart`.
- **Test kiểm chứng:** `bug04_monthEndHalfOpenBoundary`.

### 5. Lỗi lịch lặp cuối tháng (Recurring Month-End Clamping)
- **Vấn đề:** Tạo chu kỳ định kỳ vào ngày 31. Nếu cộng tháng thông thường (`LocalDate.plusMonths(1)`), từ ngày 31 tháng 1 sẽ rơi vào ngày 28/29 tháng 2, rồi sang tháng sau lại tiếp tục bị ghim ở ngày 28 thay vì trả về ngày 31 ban đầu.
- **Giải pháp:** Thuật toán [`RecurringCalculator.java`](file:///d:/ky9/self_project/pj3/backend/src/main/java/com/tracker/expense/service/recurring/RecurringCalculator.java) lưu trữ ngày gốc (`originalDay = 31`), và tính:
  `actualDay = Math.min(originalDay, targetMonth.lengthOfMonth())`.
  - 31/01/2026 -> 28/02/2026 -> 31/03/2026.
  - Năm nhuận 2028: 31/01/2028 -> 29/02/2028 -> 31/03/2028.
- **Test kiểm chứng:** `bug05_recurringMonthEndClamping`.

### 6. Chạy lặp giao dịch định kỳ (Lack of Idempotency)
- **Vấn đề:** Cron job định kỳ chạy lại do server khởi động lại hoặc timeout mạng, làm phát sinh 2 khoản trừ tiền giống nhau.
- **Giải pháp:** Khóa duy nhất tại DB:
  `UNIQUE (recurring_rule_id, occurrence_date)` kết hợp kiểm tra `existsByRecurringRuleIdAndOccurrenceDate` trong [`RecurringService.java`](file:///d:/ky9/self_project/pj3/backend/src/main/java/com/tracker/expense/service/RecurringService.java).
- **Test kiểm chứng:** `bug06_recurringJobIdempotency`.

### 7. Tràn bộ nhớ (OOM) do tính tổng trong RAM
- **Vấn đề:** Gọi `findAll()` tải 50.000 giao dịch lên bộ nhớ JVM rồi dùng Java Stream `sum()` làm đầy Heap và treo ứng dụng.
- **Giải pháp:** Đẩy toàn bộ phép toán tính tổng xuống PostgreSQL thông qua các hàm tổng hợp SQL chuẩn (`SUM(CASE WHEN ...)` và `GROUP BY category_id`) trong [`TransactionRepository.java`](file:///d:/ky9/self_project/pj3/backend/src/main/java/com/tracker/expense/repository/TransactionRepository.java).
- **Test kiểm chứng:** Tích hợp trong `ReportServiceTest` và `TransactionRepository`.

### 8. Lỗi N+1 Query
- **Vấn đề:** Khi truy vấn danh sách 50 giao dịch, Hibernate tự động bắn thêm 50 truy vấn tìm Category và 50 truy vấn tìm PaymentMethod.
- **Giải pháp:** Cấu hình `@EntityGraph(attributePaths = {"category", "paymentMethod"})` trên các hàm tìm kiếm phân trang.

### 9. CSV Formula Injection (Excel Macro / DDE)
- **Vấn đề:** Người dùng đặt ghi chú là `=cmd|'/c calc'!A1` hoặc `-2+5+cmd|...`. Khi xuất file CSV và mở bằng Microsoft Excel, công thức sẽ tự động thực thi mã lệnh trên máy người dùng.
- **Giải pháp:** Trong [`CsvExportService.java`](file:///d:/ky9/self_project/pj3/backend/src/main/java/com/tracker/expense/service/CsvExportService.java), nếu ô dữ liệu bắt đầu bằng `=`, `+`, `-`, `@`, hệ thống tự động thêm dấu nháy đơn `'` ở đầu để Excel hiểu đây là dạng chuỗi thuần.
- **Test kiểm chứng:** `bug09_csvFormulaInjectionSanitized`.

### 10. Lỗi Font tiếng Việt khi mở CSV trên Excel (Mojibake)
- **Vấn đề:** Tệp UTF-8 không có BOM khi mở trực tiếp bằng Excel trên Windows sẽ bị lỗi ký tự tiếng Việt (ví dụ: `Ăn uống` biến thành `Äƒn uá»‘ng`).
- **Giải pháp:** [`CsvExportService.java`](file:///d:/ky9/self_project/pj3/backend/src/main/java/com/tracker/expense/service/CsvExportService.java) luôn ghi ký tự Byte Order Mark `\uFEFF` ở đầu stream.
- **Test kiểm chứng:** `bug10_csvUtf8BomHeaderPresent`.

### 11. Lọt dữ liệu xóa mềm (Soft Delete Leakage)
- **Vấn đề:** Người dùng đã xóa giao dịch nhưng tổng chi tiêu trong tháng hay ngân sách vẫn tính gộp số tiền đó.
- **Giải pháp:** [`TransactionSpecification.java`](file:///d:/ky9/self_project/pj3/backend/src/main/java/com/tracker/expense/repository/specification/TransactionSpecification.java) và mọi Native/JPA Query luôn có điều kiện `deleted_at IS NULL`.
- **Test kiểm chứng:** `bug07_softDeleteExclusion`.

### 12. Lỗi khóa ngoại khi xóa danh mục đã phát sinh giao dịch
- **Vấn đề:** User bấm xóa danh mục "Ăn uống". Nếu hard-delete `DELETE FROM categories`, PostgreSQL sẽ ném lỗi `foreign key violation` do các giao dịch cũ đang trỏ tới.
- **Giải pháp:** [`CategoryService.java`](file:///d:/ky9/self_project/pj3/backend/src/main/java/com/tracker/expense/service/CategoryService.java) kiểm tra `existsByUserIdAndCategoryIdAndDeletedAtIsNull`: nếu đã có giao dịch thì chuyển trạng thái `archived = true`, nếu chưa có mới thực hiện xóa vật lý.
- **Test kiểm chứng:** `bug14_categoryDeletionSafetyWithTransactions`.

### 13. Lệch loại giữa Danh mục và Giao dịch (Type Mismatch)
- **Vấn đề:** Người dùng tạo giao dịch CHI TIÊU (`EXPENSE`) nhưng lại chọn danh mục THU NHẬP (`INCOME` ví dụ "Lương").
- **Giải pháp:** [`TransactionService.java`](file:///d:/ky9/self_project/pj3/backend/src/main/java/com/tracker/expense/service/TransactionService.java) so sánh `category.getType() != request.getType()` và ném `BadRequestException` lập tức.
- **Test kiểm chứng:** `bug08_categoryTypeMismatch`.

### 14. Mất mốc tháng trong biểu đồ xu hướng (Skewed Chart X-Axis)
- **Vấn đề:** Nếu tháng 8 không có giao dịch, câu lệnh SQL thông thường chỉ trả về tháng 7 và tháng 9. Biểu đồ sẽ bị nối liền tháng 7 sang tháng 9, gây sai lệch trục thời gian.
- **Giải pháp:** [`ReportService.java`](file:///d:/ky9/self_project/pj3/backend/src/main/java/com/tracker/expense/service/ReportService.java) khởi tạo một LinkedHashMap chứa đủ 12 tháng liên tục và gán giá trị mặc định `BigDecimal.ZERO` (Zero-fill).
- **Test kiểm chứng:** `bug11_zeroFillMissingMonthsInTrend`.

### 15. Trễ cảnh báo vượt hạn mức ngân sách
- **Vấn đề:** Người dùng vừa quẹt thẻ một khoản tiền lớn làm vượt ngân sách, nhưng hệ thống không có phản hồi nào cho đến khi họ tự vào xem tab Ngân sách.
- **Giải pháp:** Tại [`TransactionService.createTransaction`](file:///d:/ky9/self_project/pj3/backend/src/main/java/com/tracker/expense/service/TransactionService.java), hệ thống kiểm tra ngay hạn mức hiện tại và trả về danh sách `budgetAlerts`. Giao diện Flutter hiển thị ngay SnackBar cảnh báo màu đỏ (Exceeded) hoặc vàng (Warning).
- **Test kiểm chứng:** `bug12_budgetThresholdRealtimeEvaluation`.

### 16. Nhập số tiền âm hoặc bằng 0
- **Vấn đề:** Người dùng hoặc bot gửi request với số tiền âm `-50000` làm đảo lộn luồng tiền hoặc tạo giao dịch ảo.
- **Giải pháp:** DTO validation annotation `@DecimalMin(value = "0.01")` và `@Digits(integer = 12, fraction = 2)` kiểm soát chặt chẽ ở tầng ngoài cùng.
- **Test kiểm chứng:** `bug13_negativeAmountRejected`.

### 17. Tranh chấp làm mới Token (Silent Refresh Token Race Condition)
- **Vấn đề:** Khi Access Token hết hạn, nhiều request đồng thời gửi lên API cùng lúc dẫn đến gọi Refresh Token nhiều lần, gây hủy phiên ngoài ý muốn.
- **Giải pháp:** [`ApiClient.java`](file:///d:/ky9/self_project/pj3/frontend/lib/core/network/api_client.dart) trong Flutter sử dụng cờ `_isRefreshing` và khóa hàng đợi `QueuedInterceptor` của Dio: chỉ có duy nhất 1 request thực hiện refresh token, các request khác tạm dừng và thử lại khi có token mới.

### 18. Tái sử dụng Refresh Token bị đánh cắp (Token Replay / Theft)
- **Vấn đề:** Refresh token dài hạn (7 ngày) nếu bị lộ có thể bị kẻ gian lợi dụng cấp phát token mới liên tục.
- **Giải pháp:** Refresh Token Rotation (RTR): Mỗi Refresh Token chỉ được dùng đúng một lần. Khi refresh thành công, token cũ bị đưa vào danh sách thu hồi (`isRevoked = true`). Nếu token đã thu hồi bị gửi lại, hệ thống lập tức từ chối và yêu cầu đăng nhập lại.
- **Test kiểm chứng:** `bug15_refreshTokenRotationAndRevocation`.

### 19. Tấn công SQL Injection qua chuỗi tìm kiếm (`q`)
- **Vấn đề:** Người dùng nhập chuỗi `' OR '1'='1` vào ô tìm kiếm nhằm bypass câu lệnh WHERE.
- **Giải pháp:** [`TransactionSpecification.java`](file:///d:/ky9/self_project/pj3/backend/src/main/java/com/tracker/expense/repository/specification/TransactionSpecification.java) dùng JPA Criteria API để bind tham số dạng Parameterized Expression, không bao giờ nối chuỗi SQL thủ công.
- **Test kiểm chứng:** `bug16_sqlInjectionNeutralizedInSpecification`.

### 20. Số thập phân lớn bị định dạng lũy thừa (`1E+6`)
- **Vấn đề:** Khi format số tiền `1000000.00`, thư viện JSON mặc định có thể xuất dạng khoa học `1E+6`, gây lỗi parse số trên client.
- **Giải pháp:** Bật cấu hình `spring.jackson.generator.write-bigdecimal-as-plain: true` trong [`application.yml`](file:///d:/ky9/self_project/pj3/backend/src/main/resources/application.yml).
- **Test kiểm chứng:** `bug17_jacksonPlainBigDecimalSerialization`.
