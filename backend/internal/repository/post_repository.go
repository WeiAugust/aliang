package repository

import (
	"context"
	"sort"

	"gorm.io/gorm"

	"github.com/WeiAugust/aliang/backend/internal/model"
)

// postRepository implements PostRepository interface
type postRepository struct {
	db *gorm.DB
}

// NewPostRepository creates a new post repository
func NewPostRepository(db *gorm.DB) PostRepository {
	return &postRepository{db: db}
}

// Create creates a new post
func (r *postRepository) Create(ctx context.Context, post *model.Post) error {
	return r.db.WithContext(ctx).Create(post).Error
}

// GetByID gets a post by ID
func (r *postRepository) GetByID(ctx context.Context, id int64) (*model.Post, error) {
	var post model.Post
	err := r.db.WithContext(ctx).
		Preload("User").
		Preload("Media").
		Preload("Hashtags").
		First(&post, id).Error
	if err != nil {
		return nil, err
	}
	return &post, nil
}

// Update updates a post
func (r *postRepository) Update(ctx context.Context, post *model.Post) error {
	return r.db.WithContext(ctx).Save(post).Error
}

// Delete soft deletes a post
func (r *postRepository) Delete(ctx context.Context, id int64) error {
	return r.db.WithContext(ctx).Delete(&model.Post{}, id).Error
}

// List lists posts with pagination
func (r *postRepository) List(ctx context.Context, offset, limit int) ([]*model.Post, error) {
	var posts []*model.Post
	err := r.db.WithContext(ctx).
		Preload("User").
		Preload("Media").
		Where("visibility = ? AND deleted_at IS NULL", "public").
		Offset(offset).
		Limit(limit).
		Order("created_at DESC").
		Find(&posts).Error
	return posts, err
}

// ListByIDs lists posts by ids while preserving the input order
func (r *postRepository) ListByIDs(ctx context.Context, ids []int64) ([]*model.Post, error) {
	if len(ids) == 0 {
		return []*model.Post{}, nil
	}

	var posts []*model.Post
	err := r.db.WithContext(ctx).
		Preload("User").
		Preload("Media").
		Where("id IN ? AND deleted_at IS NULL", ids).
		Find(&posts).Error
	if err != nil {
		return nil, err
	}

	position := make(map[int64]int, len(ids))
	for index, id := range ids {
		position[id] = index
	}

	sort.Slice(posts, func(left, right int) bool {
		leftPosition, ok := position[posts[left].ID]
		if !ok {
			leftPosition = len(ids)
		}

		rightPosition, ok := position[posts[right].ID]
		if !ok {
			rightPosition = len(ids)
		}

		return leftPosition < rightPosition
	})

	return posts, nil
}

// ListByUserID lists posts by user ID
func (r *postRepository) ListByUserID(ctx context.Context, userID int64, offset, limit int) ([]*model.Post, error) {
	var posts []*model.Post
	err := r.db.WithContext(ctx).
		Preload("User").
		Preload("Media").
		Where("user_id = ? AND deleted_at IS NULL", userID).
		Offset(offset).
		Limit(limit).
		Order("created_at DESC").
		Find(&posts).Error
	return posts, err
}

// Search searches posts by query
func (r *postRepository) Search(ctx context.Context, query string, offset, limit int) ([]*model.Post, error) {
	var posts []*model.Post
	err := r.db.WithContext(ctx).
		Preload("User").
		Preload("Media").
		Where("visibility = ? AND deleted_at IS NULL", "public").
		Where(
			"to_tsvector('simple', coalesce(title,'') || ' ' || coalesce(content,'')) @@ plainto_tsquery('simple', ?) OR title ILIKE ? OR content ILIKE ?",
			query, "%"+query+"%", "%"+query+"%",
		).
		Offset(offset).
		Limit(limit).
		Order("created_at DESC").
		Find(&posts).Error
	return posts, err
}

// Count counts total posts
func (r *postRepository) Count(ctx context.Context) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&model.Post{}).
		Where("deleted_at IS NULL").
		Count(&count).Error
	return count, err
}

// IncrementLikeCount increments like count
func (r *postRepository) IncrementLikeCount(ctx context.Context, postID int64) error {
	return r.db.WithContext(ctx).
		Model(&model.Post{}).
		Where("id = ?", postID).
		UpdateColumn("like_count", gorm.Expr("like_count + ?", 1)).Error
}

// DecrementLikeCount decrements like count
func (r *postRepository) DecrementLikeCount(ctx context.Context, postID int64) error {
	return r.db.WithContext(ctx).
		Model(&model.Post{}).
		Where("id = ?", postID).
		UpdateColumn("like_count", gorm.Expr("like_count - ?", 1)).Error
}

// IncrementCommentCount increments comment count
func (r *postRepository) IncrementCommentCount(ctx context.Context, postID int64) error {
	return r.db.WithContext(ctx).
		Model(&model.Post{}).
		Where("id = ?", postID).
		UpdateColumn("comment_count", gorm.Expr("comment_count + ?", 1)).Error
}

// DecrementCommentCount decrements comment count
func (r *postRepository) DecrementCommentCount(ctx context.Context, postID int64) error {
	return r.db.WithContext(ctx).
		Model(&model.Post{}).
		Where("id = ?", postID).
		UpdateColumn("comment_count", gorm.Expr("comment_count - ?", 1)).Error
}

// A3: GetByIDWithVisibility gets a post by ID with visibility check
func (r *postRepository) GetByIDWithVisibility(ctx context.Context, id int64, userID int64, isAdmin bool) (*model.Post, error) {
	var post model.Post

	query := r.db.WithContext(ctx).
		Preload("User").
		Preload("Media").
		Preload("Hashtags").
		First(&post, id)

	if err := query.Error; err != nil {
		return nil, err
	}

	// If not admin and not owner, check visibility
	if !isAdmin && post.UserID != userID && post.Visibility == "self_only" {
		return nil, gorm.ErrRecordNotFound
	}

	return &post, nil
}

// A3: ListByUserIDWithVisibility lists posts by user ID with visibility check
func (r *postRepository) ListByUserIDWithVisibility(ctx context.Context, userID, viewerID int64, isAdmin bool, offset, limit int) ([]*model.Post, error) {
	var posts []*model.Post

	query := r.db.WithContext(ctx).
		Preload("User").
		Preload("Media").
		Where("user_id = ? AND deleted_at IS NULL", userID)

	// If not admin and not the owner, hide self_only posts
	if !isAdmin && userID != viewerID {
		query.Where("visibility != ?", "self_only")
	}

	err := query.
		Offset(offset).
		Limit(limit).
		Order("created_at DESC").
		Find(&posts).Error

	return posts, err
}

// A3: ListAllForAdmin lists all posts for admin (no visibility filter)
func (r *postRepository) ListAllForAdmin(ctx context.Context, offset, limit int) ([]*model.Post, error) {
	var posts []*model.Post
	err := r.db.WithContext(ctx).
		Preload("User").
		Preload("Media").
		Where("deleted_at IS NULL").
		Offset(offset).
		Limit(limit).
		Order("created_at DESC").
		Find(&posts).Error
	return posts, err
}

// A5: GetDailyNewPosts gets the count of new posts in the last 24 hours
func (r *postRepository) GetDailyNewPosts(ctx context.Context) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&model.Post{}).
		Where("created_at >= NOW() - INTERVAL '24 hours'").
		Count(&count).Error
	return count, err
}
