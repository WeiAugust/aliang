-- Add password_hash column to users table
ALTER TABLE users ADD COLUMN password_hash VARCHAR(255);

-- Update admin user password with bcrypt hash of 'admin123'
-- Generated using: htpasswd -nbBC 10 "" admin123
-- Password: admin123
UPDATE users SET password_hash = '$2a$10$r7Y1fACnvx1MQv1d8tKqE.X5JKW9HNMdYMNVbNHZJb6s3eKj3.KG' WHERE role = 'admin';
