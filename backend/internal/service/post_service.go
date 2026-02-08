package service

import (
	"context"
	"fmt"
	"regexp"
	"strings"

	"github.com/WeiAugust/aliang/backend/internal/model"
	"github.com/WeiAugust/aliang/backend/internal/repository"
)

// PostService handles post operations
type PostService struct {
	postRepo        repository.PostRepository
	hashtagRepo     repository.HashtagRepository
	postHashtagRepo repository.PostHashtagRepository
}

// NewPostService creates a new post service
func NewPostService(
	postRepo repository.PostRepository,
	hashtagRepo repository.HashtagRepository,
	postHashtagRepo repository.PostHashtagRepository,
) *PostService {
	return &PostService{
		postRepo:        postRepo,
		hashtagRepo:     hashtagRepo,
		postHashtagRepo: postHashtagRepo,
	}
}

// Create creates a new post
func (s *PostService) Create(ctx context.Context, post *model.Post) error {
	// Create post
	if err := s.postRepo.Create(ctx, post); err != nil {
		return fmt.Errorf("failed to create post: %w", err)
	}

	// Extract and create hashtags
	hashtags := extractHashtags(post.Content)
	for _, tag := range hashtags {
		// Get or create hashtag
		hashtag, err := s.hashtagRepo.GetOrCreate(ctx, tag)
		if err != nil {
			return fmt.Errorf("failed to get or create hashtag: %w", err)
		}

		// Create post-hashtag relationship
		if err := s.postHashtagRepo.Create(ctx, post.ID, hashtag.ID); err != nil {
			return fmt.Errorf("failed to create post-hashtag relationship: %w", err)
		}

		// Increment hashtag post count
		if err := s.hashtagRepo.IncrementPostCount(ctx, hashtag.ID); err != nil {
			return fmt.Errorf("failed to increment hashtag post count: %w", err)
		}
	}

	return nil
}

// GetByID gets a post by ID
func (s *PostService) GetByID(ctx context.Context, id int64) (*model.Post, error) {
	post, err := s.postRepo.GetByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("failed to get post: %w", err)
	}
	return post, nil
}

// Update updates a post
func (s *PostService) Update(ctx context.Context, post *model.Post) error {
	if err := s.postRepo.Update(ctx, post); err != nil {
		return fmt.Errorf("failed to update post: %w", err)
	}
	return nil
}

// Delete deletes a post
func (s *PostService) Delete(ctx context.Context, id int64) error {
	// Get post to verify it exists
	_, err := s.postRepo.GetByID(ctx, id)
	if err != nil {
		return fmt.Errorf("failed to get post: %w", err)
	}

	// Get hashtags for the post
	hashtags, err := s.postHashtagRepo.ListHashtagsByPostID(ctx, id)
	if err != nil {
		return fmt.Errorf("failed to get hashtags: %w", err)
	}

	// Delete post-hashtag relationships
	if err := s.postHashtagRepo.DeleteByPostID(ctx, id); err != nil {
		return fmt.Errorf("failed to delete post-hashtag relationships: %w", err)
	}

	// Decrement hashtag post counts
	for _, hashtag := range hashtags {
		if err := s.hashtagRepo.DecrementPostCount(ctx, hashtag.ID); err != nil {
			return fmt.Errorf("failed to decrement hashtag post count: %w", err)
		}
	}

	// Delete post
	if err := s.postRepo.Delete(ctx, id); err != nil {
		return fmt.Errorf("failed to delete post: %w", err)
	}

	return nil
}

// List lists posts with pagination
func (s *PostService) List(ctx context.Context, offset, limit int) ([]*model.Post, error) {
	posts, err := s.postRepo.List(ctx, offset, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to list posts: %w", err)
	}
	return posts, nil
}

// ListByUserID lists posts by user ID
func (s *PostService) ListByUserID(ctx context.Context, userID int64, offset, limit int) ([]*model.Post, error) {
	posts, err := s.postRepo.ListByUserID(ctx, userID, offset, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to list posts by user: %w", err)
	}
	return posts, nil
}

// Search searches posts by query
func (s *PostService) Search(ctx context.Context, query string, offset, limit int) ([]*model.Post, error) {
	posts, err := s.postRepo.Search(ctx, query, offset, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to search posts: %w", err)
	}
	return posts, nil
}

// Count counts total posts
func (s *PostService) Count(ctx context.Context) (int64, error) {
	count, err := s.postRepo.Count(ctx)
	if err != nil {
		return 0, fmt.Errorf("failed to count posts: %w", err)
	}
	return count, nil
}

// extractHashtags extracts hashtags from content
func extractHashtags(content string) []string {
	// Regular expression to match hashtags
	re := regexp.MustCompile(`#(\w+)`)
	matches := re.FindAllStringSubmatch(content, -1)

	// Extract unique hashtags
	seen := make(map[string]bool)
	var hashtags []string
	for _, match := range matches {
		if len(match) > 1 {
			tag := strings.ToLower(match[1])
			if !seen[tag] {
				seen[tag] = true
				hashtags = append(hashtags, tag)
			}
		}
	}

	return hashtags
}
