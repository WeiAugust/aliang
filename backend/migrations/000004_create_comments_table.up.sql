-- Create comments table
CREATE TABLE IF NOT EXISTS comments (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    post_id BIGINT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- Create indexes
CREATE INDEX idx_comments_post_id ON comments(post_id, created_at DESC);
CREATE INDEX idx_comments_user_id ON comments(user_id);
CREATE INDEX idx_comments_deleted_at ON comments(deleted_at);

-- Add comments
COMMENT ON TABLE comments IS 'User comments on posts';
