package repository

import (
	"context"

	"gorm.io/gorm"

	"github.com/WeiAugust/aliang/backend/internal/model"
)

// hashtagRepository implements HashtagRepository interface
type hashtagRepository struct {
	db *gorm.DB
}

// NewHashtagRepository creates a new hashtag repository
func NewHashtagRepository(db *gorm.DB) HashtagRepository {
	return &hashtagRepository{db: db}
}

// Create creates a new hashtag
func (r *hashtagRepository) Create(ctx context.Context, hashtag *model.Hashtag) error {
	return r.db.WithContext(ctx).Create(hashtag).Error
}

// GetByName gets a hashtag by name
func (r *hashtagRepository) GetByName(ctx context.Context, name string) (*model.Hashtag, error) {
	var hashtag model.Hashtag
	err := r.db.WithContext(ctx).Where("name = ?", name).First(&hashtag).Error
	if err != nil {
		return nil, err
	}
	return &hashtag, nil
}

// GetOrCreate gets or creates a hashtag
func (r *hashtagRepository) GetOrCreate(ctx context.Context, name string) (*model.Hashtag, error) {
	var hashtag model.Hashtag
	err := r.db.WithContext(ctx).
		Where("name = ?", name).
		FirstOrCreate(&hashtag, model.Hashtag{Name: name}).Error
	if err != nil {
		return nil, err
	}
	return &hashtag, nil
}

// IncrementPostCount increments post count
func (r *hashtagRepository) IncrementPostCount(ctx context.Context, id int64) error {
	return r.db.WithContext(ctx).
		Model(&model.Hashtag{}).
		Where("id = ?", id).
		UpdateColumn("post_count", gorm.Expr("post_count + ?", 1)).Error
}

// DecrementPostCount decrements post count
func (r *hashtagRepository) DecrementPostCount(ctx context.Context, id int64) error {
	return r.db.WithContext(ctx).
		Model(&model.Hashtag{}).
		Where("id = ?", id).
		UpdateColumn("post_count", gorm.Expr("post_count - ?", 1)).Error
}

// ListTrending lists trending hashtags
func (r *hashtagRepository) ListTrending(ctx context.Context, limit int) ([]*model.Hashtag, error) {
	var hashtags []*model.Hashtag
	err := r.db.WithContext(ctx).
		Order("post_count DESC").
		Limit(limit).
		Find(&hashtags).Error
	return hashtags, err
}
