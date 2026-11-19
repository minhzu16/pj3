-- Demo data only (db/demo, DEMO_MODE=true). The hash seeded by V2 does not match the documented
-- password, so the demo accounts could never sign in. Set it to a bcrypt hash of "Password123!",
-- leaving accounts whose password was already changed untouched.
UPDATE users
SET password_hash = '$2b$10$Njkdc.kp/d0K8lXi6XHJYuy8ID7xvdvjA9hGE8MU2mlXP.Zo1bk72'
WHERE email IN ('demo@example.com', 'test@example.com')
  AND password_hash = '$2a$10$GRLdNijSQMUvl/au9ofL.eDwmoohzzS7.rmNSJZ.0FxGQrvkWFsTa';
