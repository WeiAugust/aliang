-- Create hashtags table
CREATE TABLE IF NOT EXISTS hashtags (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    post_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_hashtags_name ON hashtags(name);
CREATE INDEX idx_hashtags_post_count ON hashtags(post_count DESC);

-- Add comments
COMMENT ON TABLE hashtags IS 'Hashtags extracted from posts';
COMMENT ON COLUMN hashtags.post_count IS 'Number of posts using this hashtag';
