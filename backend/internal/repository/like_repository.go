package repository

import (
	"context"

	"gorm.io/gorm"

	"github.com/WeiAugust/aliang/backend/internal/model"
)

// likeRepository implements LikeRepository interface
type likeRepository struct {
	db *gorm.DB
}

// NewLikeRepository creates a new like repository
func NewLikeRepository(db *gorm.DB) LikeRepository {
	return &likeRepository{db: db}
}

// Create creates a new like
func (r *likeRepository) Create(ctx context.Context, like *model.Like) error {
	return r.db.WithContext(ctx).Create(like).Error
}

// Delete deletes a like
func (r *likeRepository) Delete(ctx context.Context, userID, postID int64) error {
	return r.db.WithContext(ctx).
		Where("user_id = ? AND post_id = ?", userID, postID).
		Delete(&model.Like{}).Error
}

// Exists checks if a like exists
func (r *likeRepository) Exists(ctx context.Context, userID, postID int64) (bool, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&model.Like{}).
		Where("user_id = ? AND post_id = ?", userID, postID).
		Count(&count).Error
	return count > 0, err
}

// CountByPostID counts likes by post ID
func (r *likeRepository) CountByPostID(ctx context.Context, postID int64) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&model.Like{}).
		Where("post_id = ?", postID).
		Count(&count).Error
	return count, err
}

// Count counts total likes
func (r *likeRepository) Count(ctx context.Context) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&model.Like{}).Count(&count).Error
	return count, err
}
