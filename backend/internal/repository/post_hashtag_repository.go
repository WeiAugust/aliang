package repository

import (
	"context"

	"gorm.io/gorm"

	"github.com/WeiAugust/aliang/backend/internal/model"
)

// postHashtagRepository implements PostHashtagRepository interface
type postHashtagRepository struct {
	db *gorm.DB
}

// NewPostHashtagRepository creates a new post-hashtag repository
func NewPostHashtagRepository(db *gorm.DB) PostHashtagRepository {
	return &postHashtagRepository{db: db}
}

// Create creates a new post-hashtag relationship
func (r *postHashtagRepository) Create(ctx context.Context, postID, hashtagID int64) error {
	postHashtag := &model.PostHashtag{
		PostID:    postID,
		HashtagID: hashtagID,
	}
	return r.db.WithContext(ctx).Create(postHashtag).Error
}

// DeleteByPostID deletes all hashtags for a post
func (r *postHashtagRepository) DeleteByPostID(ctx context.Context, postID int64) error {
	return r.db.WithContext(ctx).
		Where("post_id = ?", postID).
		Delete(&model.PostHashtag{}).Error
}

// ListHashtagsByPostID lists hashtags for a post
func (r *postHashtagRepository) ListHashtagsByPostID(ctx context.Context, postID int64) ([]*model.Hashtag, error) {
	var hashtags []*model.Hashtag
	err := r.db.WithContext(ctx).
		Joins("JOIN post_hashtags ON post_hashtags.hashtag_id = hashtags.id").
		Where("post_hashtags.post_id = ?", postID).
		Find(&hashtags).Error
	return hashtags, err
}

// ListPostsByHashtagID lists posts for a hashtag
func (r *postHashtagRepository) ListPostsByHashtagID(ctx context.Context, hashtagID int64, offset, limit int) ([]*model.Post, error) {
	var posts []*model.Post
	err := r.db.WithContext(ctx).
		Preload("User").
		Preload("Media").
		Joins("JOIN post_hashtags ON post_hashtags.post_id = posts.id").
		Where("post_hashtags.hashtag_id = ? AND posts.visibility = ? AND posts.deleted_at IS NULL", hashtagID, "public").
		Offset(offset).
		Limit(limit).
		Order("posts.created_at DESC").
		Find(&posts).Error
	return posts, err
}
