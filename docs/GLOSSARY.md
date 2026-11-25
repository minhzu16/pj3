# Domain Glossary — Personal Expense & Budget Tracker (`pj3`)

Canonical terminology used across the Spring Boot backend (`com.tracker.expense`), PostgreSQL schema (`V1__init_schema.sql`), and Flutter frontend (`expense_tracker_frontend`).

| Term | Definition | Code / Schema Location |
|---|---|---|
| **User** | An authenticated account owner with isolated financial records, default currency (`VND`), and timezone (`Asia/Ho_Chi_Minh`). | `users` table, `User.java`, `UserController.java` |
| **Transaction** | A single income or expense ledger entry belonging to a user, with an exact positive `NUMERIC(14,2)` (`BigDecimal`/`Decimal`) amount, `txnDate`, `Category`, optional `PaymentMethod`, and optional `note`. Supports soft deletion via `deleted_at`. | `transactions` table, `Transaction.java`, `TransactionService.java` |
| **TransactionType** | The direction of money flow for a transaction or category: `INCOME` (`income`) or `EXPENSE` (`expense`). | `txn_type` enum, `TransactionType.java` |
| **Split Transaction** | A composite expense action that atomically creates multiple `Transaction` records across different categories from a single user submission, returning combined budget alerts. | `CreateSplitTransactionRequest.java`, `SplitTransactionResponse.java`, `TransactionService.java` |
| **Category** | A user-scoped classification for transactions (`name`, `type`, `color`, `icon`) that can be archived (`archived = true`) without breaking historical ledger references. | `categories` table, `Category.java`, `CategoryService.java` |
| **PaymentMethod** | A user-scoped funding source (e.g., cash, bank card, e-wallet) attached to transactions or recurring rules, supporting archiving. | `payment_methods` table, `PaymentMethod.java`, `PaymentMethodService.java` |
| **Budget** | A monthly spending cap (`amount_limit`) for a specific `YearMonth` (stored as the first day of the month), scoped either to a single `Category` or to total monthly expenses (`category_id IS NULL`). | `budgets` table, `Budget.java`, `BudgetService.java` |
| **Budget Alert** | A threshold warning (`alert_threshold`, default `80%`) evaluated when expense transactions are recorded, indicating that spending has reached or exceeded the configured percentage of a `Budget`. | `BudgetAlertDto.java`, `TransactionWithAlertsResponse.java` |
| **RecurringRule** | A scheduled template that automatically generates `Transaction` entries on `next_run_date` according to `RecurringFrequency` (`daily`, `weekly`, `monthly`, `yearly`) and `interval_count`, with idempotent `(recurring_rule_id, occurrence_date)` uniqueness. | `recurring_rules` table, `RecurringRule.java`, `RecurringJobRunner.java` |
| **Report** | Aggregated financial analytics computed from non-deleted transactions, including monthly trends, category breakdowns, and daily cumulative spending. | `ReportController.java`, `ReportService.java`, `reports_view.dart` |
| **Auth Rate Limit** | Per-IP sliding-window throttling applied to `/api/v1/auth/**` endpoints (`app.security.auth-rate-limit.per-minute`). | `AuthRateLimitFilter.java`, `application.yml` |
