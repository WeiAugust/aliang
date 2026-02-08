package repository

import (
	"context"

	"gorm.io/gorm"

	"github.com/WeiAugust/aliang/backend/internal/model"
)

// postMediaRepository implements PostMediaRepository interface
type postMediaRepository struct {
	db *gorm.DB
}

// NewPostMediaRepository creates a new post media repository
func NewPostMediaRepository(db *gorm.DB) PostMediaRepository {
	return &postMediaRepository{db: db}
}

// Create creates a new post media record
func (r *postMediaRepository) Create(ctx context.Context, postMedia *model.PostMedia) error {
	return r.db.WithContext(ctx).Create(postMedia).Error
}

// DeleteByPostID deletes all media records for a post
func (r *postMediaRepository) DeleteByPostID(ctx context.Context, postID int64) error {
	return r.db.WithContext(ctx).Where("post_id = ?", postID).Delete(&model.PostMedia{}).Error
}

// ListByPostID lists all media records for a post
func (r *postMediaRepository) ListByPostID(ctx context.Context, postID int64) ([]*model.PostMedia, error) {
	var media []*model.PostMedia
	err := r.db.WithContext(ctx).
		Where("post_id = ?", postID).
		Order("sort_order ASC").
		Find(&media).Error
	return media, err
}
