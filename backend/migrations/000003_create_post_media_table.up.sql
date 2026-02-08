-- Create post_media table
CREATE TABLE IF NOT EXISTS post_media (
    id BIGSERIAL PRIMARY KEY,
    post_id BIGINT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    media_url VARCHAR(500) NOT NULL,
    thumbnail_url VARCHAR(500),
    media_type VARCHAR(20) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_post_media_post_id ON post_media(post_id);
CREATE INDEX idx_post_media_sort_order ON post_media(post_id, sort_order);

-- Add comments
COMMENT ON TABLE post_media IS 'Media files associated with posts';
COMMENT ON COLUMN post_media.media_type IS 'Media type: image or video';
COMMENT ON COLUMN post_media.sort_order IS 'Display order of media in post';
