# Personal Expense & Budget Tracker

> Hệ thống quản lý chi tiêu và ngân sách cá nhân chuẩn doanh nghiệp (Production-Grade), xây dựng trên nền tảng **Java 21 (Spring Boot 3.3.4)**, **PostgreSQL 16**, và **Flutter 3.29+ / Dart 3.11+ (Riverpod 2.6.1 + fl_chart)**.

---

## 1. Điểm nổi bật & Cam kết kiến trúc

1. **Độ chính xác tài chính tuyệt đối (Zero Float Inaccuracy):**
   - Backend sử dụng thuần `BigDecimal` (12 chữ số nguyên, 2 chữ số thập phân), cấu hình Jackson `write-bigdecimal-as-plain: true` để triệt tiêu ký hiệu khoa học (`1E6`).
   - Frontend sử dụng thư viện `package:decimal`, loại bỏ hoàn toàn số thực dấu phẩy động (`double`) trong logic tính toán dòng tiền và ngân sách.

2. **Bảo mật đa tầng & Cô lập dữ liệu (Defense-in-Depth against IDOR):**
   - **Tầng 1 (Authentication):** Stateless JWT filter trích xuất Subject (`UUID userId`) từ token ký thuật toán HMAC-SHA256.
   - **Tầng 2 (Service Layer):** Mọi truy vấn Spring Data JPA / Criteria API đều bắt buộc điều kiện `WHERE user_id = :userId` và `deleted_at IS NULL`.
   - **Tầng 3 (Database Layer):** Khóa ngoại kép tại PostgreSQL `FOREIGN KEY (category_id, user_id) REFERENCES categories(id, user_id)` và `FOREIGN KEY (payment_method_id, user_id) REFERENCES payment_methods(id, user_id)` ngăn chặn triệt để hành vi cross-user resource binding.
   - **Tầng 4 (Resource Enumeration Mitigation):** Trả về HTTP 404 thay vì 403 khi truy cập tài nguyên không thuộc sở hữu của người dùng.

3. **Thuật toán Chu kỳ định kỳ (Recurring Schedule Engine):**
   - Hỗ trợ End-of-Month Clamping: Giao dịch ngày 31 tháng 1 sẽ tự động điều chỉnh về ngày 28 hoặc 29 (năm nhuận) tháng 2, và khôi phục về ngày 31 tháng 3.
   - Idempotency Guarantee: Khóa duy nhất composite `(recurring_rule_id, occurrence_date)` trên cơ sở dữ liệu ngăn ngừa việc sinh giao dịch trùng lặp khi chạy lại batch job.

4. **Báo cáo & Tổng hợp cấp cơ sở dữ liệu (SQL-Level Aggregation):**
   - Xử lý mốc thời gian theo khoảng nửa mở `[start, next_start)` tránh lỗi sai lệch mili-giây cuối tháng.
   - Báo cáo 12 tháng tự động zero-fill những tháng không có giao dịch.
   - Xuất dữ liệu CSV định dạng UTF-8 BOM (`\uFEFF`) với cơ chế phòng chống CSV Formula Injection (escape các ký tự `=`, `+`, `-`, `@`).

---

## 2. Tech Stack

| Thành phần | Công nghệ / Thư viện | Vai trò |
| :--- | :--- | :--- |
| **Backend Framework** | Java 21, Spring Boot 3.3.4 | Core REST API Backend |
| **Persistence & DB** | PostgreSQL 16, Spring Data JPA, Hibernate 6 | Lưu trữ quan hệ & tổng hợp dữ liệu |
| **Database Migration** | Flyway 10 | Quản lý phiên bản schema & seed dữ liệu mẫu |
| **Security & Auth** | Spring Security 6, JJWT 0.12.6, BCrypt | Xác thực stateless, bảo vệ endpoint |
| **Mobile / Web Client** | Flutter 3.29+, Dart 3.11+ | Giao diện người dùng đa nền tảng |
| **State Management** | Flutter Riverpod 2.6.1 + Hooks | Quản lý trạng thái phản ứng (reactive state) |
| **Networking & HTTP** | Dio 5.11.1 | HTTP Client với 401 token refresh interceptor |
| **Data Visualization** | fl_chart 1.2.0 | Biểu đồ tròn (Donut), Cột (Bar), Đường (Line) |
| **DevOps & Deploy** | Docker, Docker Compose, Caddy 2 | Container hóa đa tầng, Reverse Proxy HTTPS |

---

## 3. Cấu trúc thư mục dự án

```text
pj3/
├── .github/
│   └── workflows/
│       └── ci.yml               # Automated CI for Java Maven & Flutter
├── backend/
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/tracker/expense/
│   │   │   │   ├── api/          # REST Controllers
│   │   │   │   ├── common/       # Global exception handler & ApiResponse wrapper
│   │   │   │   ├── config/       # Spring Security & App configuration
│   │   │   │   ├── dto/          # Data Transfer Objects & Validation
│   │   │   │   ├── job/          # Scheduled daily recurring jobs
│   │   │   │   ├── model/        # JPA Entities & Enums
│   │   │   │   ├── repository/   # JPA Repositories & Criteria Specifications
│   │   │   │   ├── security/     # JwtService, CustomUserDetailsService, Filters
│   │   │   │   └── service/      # Business logic services & recurring calculation
│   │   │   └── resources/
│   │   │       ├── db/migration/ # Flyway V1 DDL & V2 Demo Seeds
│   │   │       └── application.yml
│   │   └── test/                 # 41 Unit & Controller Slice Tests
│   ├── Dockerfile                # Multi-stage Maven -> Eclipse Temurin Alpine
│   └── pom.xml
├── frontend/
│   ├── lib/
│   │   ├── core/                 # Constants, Colors, Router, Network, Token Storage
│   │   ├── models/               # Category, Transaction, Budget, Report models
│   │   ├── providers/            # Riverpod Notifiers & FutureProviders
│   │   ├── views/
│   │   │   ├── auth/             # Login & Register views
│   │   │   ├── dashboard/        # KPI summary, Donut chart, Recent txns, Quick add
│   │   │   ├── transactions/     # Filterable list, note search, swipe delete
│   │   │   ├── budgets/          # Month switcher, status badges, copy month
│   │   │   └── reports/          # Donut chart, 12-month bar chart, daily line chart
│   │   └── main.dart             # ProviderScope & Dark theme configuration
│   └── pubspec.yaml
├── Caddyfile                     # Caddy reverse proxy configuration
├── docker-compose.yml            # Local dev PostgreSQL service
├── docker-compose.prod.yml       # Production stack (Postgres + Backend + Caddy)
└── README.md
```

---

## 4. Hướng dẫn cài đặt & Khởi chạy

### Điều kiện tiên quyết
- **Java Development Kit (JDK):** Phiên bản 21 trở lên
- **Maven:** 3.9+
- **Flutter SDK:** 3.29+
- **Docker & Docker Compose:** Cài đặt sẵn trên máy

### 4.1. Khởi động Cơ sở dữ liệu nội bộ
Sử dụng Docker Compose để khởi chạy PostgreSQL 16:
```bash
rtk docker compose up -d postgres
```
Cơ sở dữ liệu sẽ lắng nghe tại `localhost:5432` với tài khoản `postgres` / `postgres`, database `expense_tracker`.

### 4.2. Khởi động Backend (Spring Boot 3)
Lần đầu: sao chép `.env.example` thành `backend/.env` và điền `JWT_SECRET` (≥ 32 ký tự). Backend **không khởi động** nếu thiếu. Sau đó chuyển vào thư mục `backend` và chạy Maven:
```bash
cp .env.example backend/.env   # rồi điền JWT_SECRET
cd backend
rtk mvn spring-boot:run
```
Flyway sẽ tự động thực thi `db/migration/V1__init_schema.sql`. Dữ liệu demo `db/demo/V2__seed_demo_data.sql` **chỉ được chạy khi `DEMO_MODE=true`** (đã bật sẵn trong `.env.example` cho môi trường dev; mặc định là tắt).
Backend sẽ hoạt động tại địa chỉ: `http://localhost:8080/api/v1`.

Tài khoản kiểm thử dựng sẵn (chỉ có ở demo mode):
- **Email:** `demo@example.com`
- **Mật khẩu:** `Password123!`

> **Database đã deploy trước thay đổi này** vẫn còn 2 tài khoản demo với mật khẩu công khai. Backend vẫn khởi động bình thường; hãy xoá chúng (dữ liệu liên quan bị xoá theo nhờ `ON DELETE CASCADE`):
> ```sql
> DELETE FROM users WHERE email IN ('demo@example.com', 'test@example.com');
> ```

### 4.3. Khởi động Frontend (Flutter Client)
Chuyển vào thư mục `frontend`:
```bash
cd frontend
rtk flutter pub get
rtk flutter run -d chrome   # Hoặc chọn Windows / Android Emulator
```

---

## 5. Danh mục REST API

| Nhóm API | Method | Endpoint | Mô tả |
| :--- | :--- | :--- | :--- |
| **Auth** | `POST` | `/api/v1/auth/register` | Đăng ký tài khoản (tự động tạo danh mục mặc định) |
| | `POST` | `/api/v1/auth/login` | Đăng nhập nhận JWT Access & Refresh token |
| | `POST` | `/api/v1/auth/refresh` | Cấp mới Access Token qua Refresh Token Rotation |
| | `POST` | `/api/v1/auth/logout` | Hủy Refresh Token hiện tại |
| | `GET` | `/api/v1/me` | Lấy thông tin tài khoản người dùng đăng nhập |
| **Categories** | `GET` | `/api/v1/categories` | Danh sách danh mục (chi tiêu/thu nhập) |
| | `POST` | `/api/v1/categories` | Tạo mới danh mục người dùng |
| | `DELETE` | `/api/v1/categories/{id}` | Xóa hoặc lưu trữ mềm danh mục nếu đã phát sinh giao dịch |
| **Transactions** | `GET` | `/api/v1/transactions` | Lọc giao dịch động (`from`, `to`, `type`, `q`, `page`) |
| | `POST` | `/api/v1/transactions` | Tạo giao dịch mới (kèm cảnh báo ngưỡng ngân sách) |
| | `PATCH` | `/api/v1/transactions/{id}` | Cập nhật thông tin giao dịch |
| | `DELETE` | `/api/v1/transactions/{id}` | Xóa mềm giao dịch (`deleted_at = NOW()`) |
| | `GET` | `/api/v1/transactions/export.csv` | Xuất CSV an toàn (UTF-8 BOM + Formula Injection sanitized) |
| **Budgets** | `GET` | `/api/v1/budgets?month=yyyy-MM` | Danh sách ngân sách theo tháng kèm tiến độ & trạng thái |
| | `POST` | `/api/v1/budgets` | Tạo ngân sách danh mục hoặc ngân sách tổng |
| | `POST` | `/api/v1/budgets/copy` | Sao chép toàn bộ hạn mức từ tháng trước sang tháng mới |
| | `DELETE` | `/api/v1/budgets/{id}` | Xóa ngân sách |
| **Reports** | `GET` | `/api/v1/reports/summary?month=yyyy-MM` | Tổng quan thu chi, số dư ròng, % thay đổi với tháng trước |
| | `GET` | `/api/v1/reports/by-category` | Cơ cấu chi tiêu theo danh mục (Donut chart data) |
| | `GET` | `/api/v1/reports/monthly-trend?months=12` | Xu hướng thu chi 12 tháng (zero-filled missing months) |
| | `GET` | `/api/v1/reports/daily?month=yyyy-MM` | Dòng chi tiêu lũy kế từng ngày trong tháng |

---

## 6. Kiểm thử & Đảm bảo chất lượng

### Backend Test Suite
Chạy toàn bộ 41 unit & slice tests:
```bash
cd backend
rtk mvn test
```
- Đã kiểm tra đầy đủ: `AuthControllerTest`, `HealthControllerTest`, `JwtServiceTest`, `AuthServiceTest`, `BudgetServiceTest`, `CategoryServiceTest`, `CsvExportServiceTest`, `RecurringCalculatorTest`, `RecurringServiceTest`, `ReportServiceTest`, `TransactionServiceTest`.

### Frontend Code Quality & Tests
```bash
cd frontend
rtk flutter analyze
rtk flutter test
```
- Phân tích code tĩnh: 0 warning, 0 error.
- Kiểm thử đơn vị mô hình dữ liệu: 100% passed.

---

## 7. Triển khai Production (Docker & Caddy)

Hệ thống đã sẵn sàng triển khai toàn diện qua `docker-compose.prod.yml`:
```bash
rtk docker compose -f docker-compose.prod.yml up -d --build
```
Dịch vụ bao gồm:
1. **Postgres 16:** Lưu trữ trên volume `postgres_prod_data`, cấu hình `restart: always` và healthcheck.
2. **Backend API:** Multi-stage Dockerfile chạy trên môi trường `eclipse-temurin:21-jre-alpine` nhẹ, bảo mật với tài khoản non-root `appuser`.
3. **Caddy 2 Reverse Proxy:** Tự động điều phối traffic, nén gzip/zstd, và cấu hình sẵn sàng cho HTTPS tự động.
