package repository

import (
	"context"

	"gorm.io/gorm"

	"github.com/WeiAugust/aliang/backend/internal/model"
)

// commentRepository implements CommentRepository interface
type commentRepository struct {
	db *gorm.DB
}

// NewCommentRepository creates a new comment repository
func NewCommentRepository(db *gorm.DB) CommentRepository {
	return &commentRepository{db: db}
}

// Create creates a new comment
func (r *commentRepository) Create(ctx context.Context, comment *model.Comment) error {
	return r.db.WithContext(ctx).Create(comment).Error
}

// GetByID gets a comment by ID
func (r *commentRepository) GetByID(ctx context.Context, id int64) (*model.Comment, error) {
	var comment model.Comment
	err := r.db.WithContext(ctx).
		Preload("User").
		First(&comment, id).Error
	if err != nil {
		return nil, err
	}
	return &comment, nil
}

// Delete soft deletes a comment
func (r *commentRepository) Delete(ctx context.Context, id int64) error {
	return r.db.WithContext(ctx).Delete(&model.Comment{}, id).Error
}

// ListByPostID lists comments by post ID
func (r *commentRepository) ListByPostID(ctx context.Context, postID int64, offset, limit int) ([]*model.Comment, error) {
	var comments []*model.Comment
	err := r.db.WithContext(ctx).
		Preload("User").
		Where("post_id = ? AND deleted_at IS NULL", postID).
		Offset(offset).
		Limit(limit).
		Order("created_at DESC").
		Find(&comments).Error
	return comments, err
}

// Count counts total comments
func (r *commentRepository) Count(ctx context.Context) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&model.Comment{}).
		Where("deleted_at IS NULL").
		Count(&count).Error
	return count, err
}

// CountByPostID counts comments by post ID
func (r *commentRepository) CountByPostID(ctx context.Context, postID int64) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&model.Comment{}).
		Where("post_id = ? AND deleted_at IS NULL", postID).
		Count(&count).Error
	return count, err
}
