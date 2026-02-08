package service

import (
	"context"
	"fmt"

	"github.com/WeiAugust/aliang/backend/internal/model"
	"github.com/WeiAugust/aliang/backend/internal/repository"
)

type interactionPostRepo interface {
	IncrementLikeCount(ctx context.Context, postID int64) error
	DecrementLikeCount(ctx context.Context, postID int64) error
	IncrementCommentCount(ctx context.Context, postID int64) error
	DecrementCommentCount(ctx context.Context, postID int64) error
}

// InteractionService handles like and comment operations
type InteractionService struct {
	likeRepo    repository.LikeRepository
	commentRepo repository.CommentRepository
	postRepo    interactionPostRepo
}

// NewInteractionService creates a new interaction service
func NewInteractionService(
	likeRepo repository.LikeRepository,
	commentRepo repository.CommentRepository,
	postRepo interactionPostRepo,
) *InteractionService {
	return &InteractionService{
		likeRepo:    likeRepo,
		commentRepo: commentRepo,
		postRepo:    postRepo,
	}
}

// ToggleLike toggles a like on a post
func (s *InteractionService) ToggleLike(ctx context.Context, userID, postID int64) (bool, error) {
	// Check if like exists
	exists, err := s.likeRepo.Exists(ctx, userID, postID)
	if err != nil {
		return false, fmt.Errorf("failed to check like existence: %w", err)
	}

	if exists {
		// Unlike: delete like and decrement count
		if err := s.likeRepo.Delete(ctx, userID, postID); err != nil {
			return false, fmt.Errorf("failed to delete like: %w", err)
		}
		if err := s.postRepo.DecrementLikeCount(ctx, postID); err != nil {
			return false, fmt.Errorf("failed to decrement like count: %w", err)
		}
		return false, nil
	} else {
		// Like: create like and increment count
		like := &model.Like{
			UserID: userID,
			PostID: postID,
		}
		if err := s.likeRepo.Create(ctx, like); err != nil {
			return false, fmt.Errorf("failed to create like: %w", err)
		}
		if err := s.postRepo.IncrementLikeCount(ctx, postID); err != nil {
			return false, fmt.Errorf("failed to increment like count: %w", err)
		}
		return true, nil
	}
}

// IsLiked checks if a user has liked a post
func (s *InteractionService) IsLiked(ctx context.Context, userID, postID int64) (bool, error) {
	exists, err := s.likeRepo.Exists(ctx, userID, postID)
	if err != nil {
		return false, fmt.Errorf("failed to check like existence: %w", err)
	}
	return exists, nil
}

// CreateComment creates a new comment
func (s *InteractionService) CreateComment(ctx context.Context, comment *model.Comment) error {
	// Create comment
	if err := s.commentRepo.Create(ctx, comment); err != nil {
		return fmt.Errorf("failed to create comment: %w", err)
	}

	// Increment post comment count
	if err := s.postRepo.IncrementCommentCount(ctx, comment.PostID); err != nil {
		return fmt.Errorf("failed to increment comment count: %w", err)
	}

	return nil
}

// DeleteComment deletes a comment
func (s *InteractionService) DeleteComment(ctx context.Context, id int64) error {
	// Get comment to get post ID
	comment, err := s.commentRepo.GetByID(ctx, id)
	if err != nil {
		return fmt.Errorf("failed to get comment: %w", err)
	}

	// Delete comment
	if err := s.commentRepo.Delete(ctx, id); err != nil {
		return fmt.Errorf("failed to delete comment: %w", err)
	}

	// Decrement post comment count
	if err := s.postRepo.DecrementCommentCount(ctx, comment.PostID); err != nil {
		return fmt.Errorf("failed to decrement comment count: %w", err)
	}

	return nil
}

// ListComments lists comments for a post
func (s *InteractionService) ListComments(ctx context.Context, postID int64, offset, limit int) ([]*model.Comment, error) {
	comments, err := s.commentRepo.ListByPostID(ctx, postID, offset, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to list comments: %w", err)
	}
	return comments, nil
}

// CountComments counts comments for a post
func (s *InteractionService) CountComments(ctx context.Context, postID int64) (int64, error) {
	count, err := s.commentRepo.CountByPostID(ctx, postID)
	if err != nil {
		return 0, fmt.Errorf("failed to count comments: %w", err)
	}
	return count, nil
}

// CountTotalLikes counts total likes
func (s *InteractionService) CountTotalLikes(ctx context.Context) (int64, error) {
	count, err := s.likeRepo.Count(ctx)
	if err != nil {
		return 0, fmt.Errorf("failed to count likes: %w", err)
	}
	return count, nil
}

// CountTotalComments counts total comments
func (s *InteractionService) CountTotalComments(ctx context.Context) (int64, error) {
	count, err := s.commentRepo.Count(ctx)
	if err != nil {
		return 0, fmt.Errorf("failed to count comments: %w", err)
	}
	return count, nil
}
