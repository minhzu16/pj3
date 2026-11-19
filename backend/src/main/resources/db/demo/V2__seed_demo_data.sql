-- Seed 2 demo users (password is: Password123!)
-- BCrypt hash: $2a$10$GRLdNijSQMUvl/au9ofL.eDwmoohzzS7.rmNSJZ.0FxGQrvkWFsTa

INSERT INTO users (id, email, password_hash, full_name, currency, timezone)
VALUES
    ('a0000000-0000-0000-0000-000000000001', 'demo@example.com', '$2a$10$GRLdNijSQMUvl/au9ofL.eDwmoohzzS7.rmNSJZ.0FxGQrvkWFsTa', 'Demo User', 'VND', 'Asia/Ho_Chi_Minh'),
    ('b0000000-0000-0000-0000-000000000002', 'test@example.com', '$2a$10$GRLdNijSQMUvl/au9ofL.eDwmoohzzS7.rmNSJZ.0FxGQrvkWFsTa', 'Test Isolation User', 'VND', 'Asia/Ho_Chi_Minh')
ON CONFLICT (id) DO NOTHING;

-- Seed Default Categories for Demo User
INSERT INTO categories (id, user_id, name, type, color, icon)
VALUES
    ('c0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Ăn uống', 'expense', '#FF5722', 'restaurant'),
    ('c0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'Đi lại', 'expense', '#2196F3', 'directions_car'),
    ('c0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001', 'Tiền nhà', 'expense', '#9C27B0', 'home'),
    ('c0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000001', 'Mua sắm', 'expense', '#E91E63', 'shopping_cart'),
    ('c0000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000001', 'Hoá đơn & Tiện ích', 'expense', '#FF9800', 'receipt_long'),
    ('c0000000-0000-0000-0000-000000000006', 'a0000000-0000-0000-0000-000000000001', 'Lương', 'income', '#4CAF50', 'payments'),
    ('c0000000-0000-0000-0000-000000000007', 'a0000000-0000-0000-0000-000000000001', 'Thưởng', 'income', '#009688', 'card_giftcard')
ON CONFLICT (id) DO NOTHING;

-- Seed Default Payment Methods for Demo User
INSERT INTO payment_methods (id, user_id, name)
VALUES
    ('d0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Tiền mặt'),
    ('d0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'Thẻ VISA / Master'),
    ('d0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001', 'Ví MoMo')
ON CONFLICT (id) DO NOTHING;

-- Seed Default Categories for Test Isolation User (To test isolation constraints)
INSERT INTO categories (id, user_id, name, type, color, icon)
VALUES
    ('c0000000-0000-0000-0000-000000000099', 'b0000000-0000-0000-0000-000000000002', 'Chi tiêu bí mật của B', 'expense', '#000000', 'lock')
ON CONFLICT (id) DO NOTHING;

INSERT INTO payment_methods (id, user_id, name)
VALUES
    ('d0000000-0000-0000-0000-000000000099', 'b0000000-0000-0000-0000-000000000002', 'Tài khoản ẩn B')
ON CONFLICT (id) DO NOTHING;
