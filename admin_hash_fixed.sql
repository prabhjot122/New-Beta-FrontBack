
-- Admin user with bcrypt-compatible hash
DELETE FROM users WHERE is_admin = TRUE;
INSERT INTO users (name, email, password_hash, is_admin, is_active, total_points, shares_count, default_rank, current_rank)
VALUES ('Sahil Saurav', 'sahilsaurav2507@gmail.com', '$2b$12$L2Yu8gTidh5Ygef/a2zdouhaSpvAWhkQbZvJ8RTfXijbpLUWZS4hq', TRUE, TRUE, 0, 0, NULL, NULL);
