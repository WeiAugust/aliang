-- Create post_hashtags junction table
CREATE TABLE IF NOT EXISTS post_hashtags (
    post_id BIGINT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    hashtag_id BIGINT NOT NULL REFERENCES hashtags(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (post_id, hashtag_id)
);

-- Create indexes
CREATE INDEX idx_post_hashtags_post_id ON post_hashtags(post_id);
CREATE INDEX idx_post_hashtags_hashtag_id ON post_hashtags(hashtag_id);

-- Add comments
COMMENT ON TABLE post_hashtags IS 'Many-to-many relationship between posts and hashtags';
