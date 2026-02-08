package repository

import (
	"context"

	"gorm.io/gorm"

	"github.com/WeiAugust/aliang/backend/internal/model"
)

// userRepository implements UserRepository interface
type userRepository struct {
	db *gorm.DB
}

// NewUserRepository creates a new user repository
func NewUserRepository(db *gorm.DB) UserRepository {
	return &userRepository{db: db}
}

// Create creates a new user
func (r *userRepository) Create(ctx context.Context, user *model.User) error {
	return r.db.WithContext(ctx).Create(user).Error
}

// GetByID gets a user by ID
func (r *userRepository) GetByID(ctx context.Context, id int64) (*model.User, error) {
	var user model.User
	err := r.db.WithContext(ctx).First(&user, id).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

// GetByPhone gets a user by phone number
func (r *userRepository) GetByPhone(ctx context.Context, phone string) (*model.User, error) {
	var user model.User
	err := r.db.WithContext(ctx).Where("phone = ?", phone).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

// Update updates a user
func (r *userRepository) Update(ctx context.Context, user *model.User) error {
	return r.db.WithContext(ctx).Save(user).Error
}

// Delete deletes a user
func (r *userRepository) Delete(ctx context.Context, id int64) error {
	return r.db.WithContext(ctx).Delete(&model.User{}, id).Error
}

// List lists users with pagination
func (r *userRepository) List(ctx context.Context, offset, limit int) ([]*model.User, error) {
	var users []*model.User
	err := r.db.WithContext(ctx).
		Offset(offset).
		Limit(limit).
		Order("created_at DESC").
		Find(&users).Error
	return users, err
}

// Count counts total users
func (r *userRepository) Count(ctx context.Context) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&model.User{}).Count(&count).Error
	return count, err
}

// GetStatsByUserID gets aggregated post/like/comment stats for a user
func (r *userRepository) GetStatsByUserID(ctx context.Context, userID int64) (postCount, likeCount, commentCount int64, err error) {
	type userStats struct {
		PostCount    int64
		LikeCount    int64
		CommentCount int64
	}

	var stats userStats
	err = r.db.WithContext(ctx).
		Model(&model.Post{}).
		Select("COUNT(*) as post_count, COALESCE(SUM(like_count), 0) as like_count, COALESCE(SUM(comment_count), 0) as comment_count").
		Where("user_id = ? AND deleted_at IS NULL", userID).
		Scan(&stats).Error
	if err != nil {
		return 0, 0, 0, err
	}

	return stats.PostCount, stats.LikeCount, stats.CommentCount, nil
}

// GetDailyActiveUsers gets the count of users active in the last 24 hours
func (r *userRepository) GetDailyActiveUsers(ctx context.Context) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&model.User{}).
		Where("updated_at >= NOW() - INTERVAL '24 hours'").
		Count(&count).Error
	return count, err
}
