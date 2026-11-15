-- Extension requirements
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS citext;

-- Users table
CREATE TABLE users (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email         CITEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    full_name     TEXT,
    currency      CHAR(3) NOT NULL DEFAULT 'VND',
    timezone      TEXT NOT NULL DEFAULT 'Asia/Ho_Chi_Minh',
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Transaction types enum
CREATE TYPE txn_type AS ENUM ('income', 'expense');

-- Categories table
CREATE TABLE categories (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name       TEXT NOT NULL,
    type       txn_type NOT NULL,
    color      TEXT,
    icon       TEXT,
    archived   BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, name, type),
    UNIQUE (id, user_id)
);

-- Payment methods table
CREATE TABLE payment_methods (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name       TEXT NOT NULL,
    archived   BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, name),
    UNIQUE (id, user_id)
);

-- Recurring rules table
CREATE TABLE recurring_rules (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type              txn_type NOT NULL,
    amount            NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    category_id       UUID NOT NULL,
    payment_method_id UUID,
    note              TEXT,
    frequency         TEXT NOT NULL CHECK (frequency IN ('daily','weekly','monthly','yearly')),
    interval_count    INT  NOT NULL DEFAULT 1 CHECK (interval_count >= 1),
    start_date        DATE NOT NULL,
    end_date          DATE,
    next_run_date     DATE NOT NULL,
    is_active         BOOLEAN NOT NULL DEFAULT true,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (id, user_id),
    FOREIGN KEY (category_id, user_id)       REFERENCES categories(id, user_id),
    FOREIGN KEY (payment_method_id, user_id) REFERENCES payment_methods(id, user_id)
);

-- Transactions table
CREATE TABLE transactions (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type              txn_type NOT NULL,
    amount            NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    txn_date          DATE NOT NULL,
    category_id       UUID NOT NULL,
    payment_method_id UUID,
    note              TEXT,
    recurring_rule_id UUID,
    occurrence_date   DATE,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at        TIMESTAMPTZ,
    FOREIGN KEY (category_id, user_id)       REFERENCES categories(id, user_id),
    FOREIGN KEY (payment_method_id, user_id) REFERENCES payment_methods(id, user_id),
    FOREIGN KEY (recurring_rule_id, user_id) REFERENCES recurring_rules(id, user_id),
    UNIQUE (recurring_rule_id, occurrence_date)
);

-- Performance indices for transactions
CREATE INDEX idx_txn_user_date     ON transactions (user_id, txn_date DESC);
CREATE INDEX idx_txn_user_category ON transactions (user_id, category_id, txn_date);

-- Budgets table
CREATE TABLE budgets (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id     UUID,
    month           DATE NOT NULL CHECK (EXTRACT(DAY FROM month) = 1),
    amount_limit    NUMERIC(14,2) NOT NULL CHECK (amount_limit > 0),
    alert_threshold SMALLINT NOT NULL DEFAULT 80 CHECK (alert_threshold BETWEEN 1 AND 100),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    FOREIGN KEY (category_id, user_id) REFERENCES categories(id, user_id)
);

-- Budget unique indices
CREATE UNIQUE INDEX uq_budget_cat   ON budgets (user_id, category_id, month) WHERE category_id IS NOT NULL;
CREATE UNIQUE INDEX uq_budget_total ON budgets (user_id, month)              WHERE category_id IS NULL;
