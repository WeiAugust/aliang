-- Add password_hash column to users table
ALTER TABLE users ADD COLUMN password_hash VARCHAR(255);

-- Update admin user password with bcrypt hash of 'admin123'
-- Generated using: python3 -c "import bcrypt; print(bcrypt.hashpw(b'admin123', bcrypt.gensalt(rounds=10)).decode())"
-- Password: admin123
UPDATE users SET password_hash = '$2b$10$qR32WEfRsM/cIiwn3YosiuT8ZqkWnW8OlSUYnJMtEsERaBkFquDf6' WHERE role = 'admin';
