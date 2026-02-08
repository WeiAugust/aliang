package repository

import (
	"context"

	"github.com/WeiAugust/aliang/backend/internal/model"
)

// UserRepository defines the interface for user data access
type UserRepository interface {
	Create(ctx context.Context, user *model.User) error
	GetByID(ctx context.Context, id int64) (*model.User, error)
	GetByPhone(ctx context.Context, phone string) (*model.User, error)
	Update(ctx context.Context, user *model.User) error
	Delete(ctx context.Context, id int64) error
	List(ctx context.Context, offset, limit int) ([]*model.User, error)
	Count(ctx context.Context) (int64, error)
}

// PostRepository defines the interface for post data access
type PostRepository interface {
	Create(ctx context.Context, post *model.Post) error
	GetByID(ctx context.Context, id int64) (*model.Post, error)
	Update(ctx context.Context, post *model.Post) error
	Delete(ctx context.Context, id int64) error
	List(ctx context.Context, offset, limit int) ([]*model.Post, error)
	ListByUserID(ctx context.Context, userID int64, offset, limit int) ([]*model.Post, error)
	Search(ctx context.Context, query string, offset, limit int) ([]*model.Post, error)
	Count(ctx context.Context) (int64, error)
	IncrementLikeCount(ctx context.Context, postID int64) error
	DecrementLikeCount(ctx context.Context, postID int64) error
	IncrementCommentCount(ctx context.Context, postID int64) error
	DecrementCommentCount(ctx context.Context, postID int64) error
}

// CommentRepository defines the interface for comment data access
type CommentRepository interface {
	Create(ctx context.Context, comment *model.Comment) error
	GetByID(ctx context.Context, id int64) (*model.Comment, error)
	Delete(ctx context.Context, id int64) error
	ListByPostID(ctx context.Context, postID int64, offset, limit int) ([]*model.Comment, error)
	Count(ctx context.Context) (int64, error)
	CountByPostID(ctx context.Context, postID int64) (int64, error)
}

// LikeRepository defines the interface for like data access
type LikeRepository interface {
	Create(ctx context.Context, like *model.Like) error
	Delete(ctx context.Context, userID, postID int64) error
	Exists(ctx context.Context, userID, postID int64) (bool, error)
	CountByPostID(ctx context.Context, postID int64) (int64, error)
	Count(ctx context.Context) (int64, error)
}

// HashtagRepository defines the interface for hashtag data access
type HashtagRepository interface {
	Create(ctx context.Context, hashtag *model.Hashtag) error
	GetByName(ctx context.Context, name string) (*model.Hashtag, error)
	GetOrCreate(ctx context.Context, name string) (*model.Hashtag, error)
	IncrementPostCount(ctx context.Context, id int64) error
	DecrementPostCount(ctx context.Context, id int64) error
	ListTrending(ctx context.Context, limit int) ([]*model.Hashtag, error)
}

// PostHashtagRepository defines the interface for post-hashtag relationship
type PostHashtagRepository interface {
	Create(ctx context.Context, postID, hashtagID int64) error
	DeleteByPostID(ctx context.Context, postID int64) error
	ListHashtagsByPostID(ctx context.Context, postID int64) ([]*model.Hashtag, error)
	ListPostsByHashtagID(ctx context.Context, hashtagID int64, offset, limit int) ([]*model.Post, error)
}
