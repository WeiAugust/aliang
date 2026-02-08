-- Create posts table
CREATE TABLE IF NOT EXISTS posts (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    post_type VARCHAR(20) NOT NULL DEFAULT 'image',
    visibility VARCHAR(20) NOT NULL DEFAULT 'public',
    label VARCHAR(20) NOT NULL DEFAULT 'normal',
    like_count INT NOT NULL DEFAULT 0,
    comment_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- Create indexes
CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX idx_posts_visibility ON posts(visibility);
CREATE INDEX idx_posts_label ON posts(label);
CREATE INDEX idx_posts_deleted_at ON posts(deleted_at);

-- Create full-text search index
CREATE INDEX idx_posts_content_search ON posts USING gin(to_tsvector('english', content));

-- Add comments
COMMENT ON TABLE posts IS 'User posts';
COMMENT ON COLUMN posts.post_type IS 'Post type: image or video';
COMMENT ON COLUMN posts.visibility IS 'Visibility: public or self_only';
COMMENT ON COLUMN posts.label IS 'Admin label: normal, recommended, or not_recommended';
