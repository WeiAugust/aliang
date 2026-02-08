-- Create likes table
CREATE TABLE IF NOT EXISTS likes (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    post_id BIGINT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, post_id)
);

-- Create indexes
CREATE INDEX idx_likes_post_id ON likes(post_id);
CREATE INDEX idx_likes_user_id ON likes(user_id);
CREATE INDEX idx_likes_user_post ON likes(user_id, post_id);

-- Add comments
COMMENT ON TABLE likes IS 'User likes on posts';
COMMENT ON CONSTRAINT likes_user_id_post_id_key ON likes IS 'Prevent duplicate likes from same user on same post';
