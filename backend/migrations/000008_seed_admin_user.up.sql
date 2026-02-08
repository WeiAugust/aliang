-- Create admin user
INSERT INTO users (phone, nickname, avatar_url, bio, role, status)
VALUES ('admin', 'Administrator', '', 'System Administrator', 'admin', 'active')
ON CONFLICT (phone) DO NOTHING;

-- Add comments
COMMENT ON TABLE users IS 'Seed data: Default admin user created';
