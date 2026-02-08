package service

import (
	"context"
	"fmt"
	"regexp"
	"strings"

	"github.com/WeiAugust/aliang/backend/internal/model"
	"github.com/WeiAugust/aliang/backend/internal/repository"
)

// postRepositoryBase defines the basic repository interface (without service extensions)
type postRepositoryBase interface {
	Create(ctx context.Context, post *model.Post) error
	GetByID(ctx context.Context, id int64) (*model.Post, error)
	Update(ctx context.Context, post *model.Post) error
	Delete(ctx context.Context, id int64) error
	List(ctx context.Context, offset, limit int) ([]*model.Post, error)
	ListByIDs(ctx context.Context, ids []int64) ([]*model.Post, error)
	ListByUserID(ctx context.Context, userID int64, offset, limit int) ([]*model.Post, error)
	CountByUserIDWithVisibility(ctx context.Context, userID, viewerID int64, isAdmin bool) (int64, error)
	Search(ctx context.Context, query string, offset, limit int) ([]*model.Post, error)
	Count(ctx context.Context) (int64, error)
	IncrementLikeCount(ctx context.Context, postID int64) error
	DecrementLikeCount(ctx context.Context, postID int64) error
	IncrementCommentCount(ctx context.Context, postID int64) error
	DecrementCommentCount(ctx context.Context, postID int64) error
	// A3: Visibility-aware methods
	GetByIDWithVisibility(ctx context.Context, id int64, userID int64, isAdmin bool) (*model.Post, error)
	ListByUserIDWithVisibility(ctx context.Context, userID, viewerID int64, isAdmin bool, offset, limit int) ([]*model.Post, error)
	ListAllForAdmin(ctx context.Context, offset, limit int) ([]*model.Post, error)
	// A5: Metrics
	GetDailyNewPosts(ctx context.Context) (int64, error)
}

type postServiceAPI interface {
	Create(ctx context.Context, post *model.Post, mediaURLs []string) error
	GetByID(ctx context.Context, id int64) (*model.Post, error)
	Update(ctx context.Context, post *model.Post) error
	Delete(ctx context.Context, id int64) error
	List(ctx context.Context, offset, limit int) ([]*model.Post, error)
	ListByIDs(ctx context.Context, ids []int64) ([]*model.Post, error)
	ListByUserID(ctx context.Context, userID int64, offset, limit int) ([]*model.Post, error)
	CountByUserIDWithVisibility(ctx context.Context, userID, viewerID int64, isAdmin bool) (int64, error)
	Search(ctx context.Context, query string, offset, limit int) ([]*model.Post, error)
	Count(ctx context.Context) (int64, error)
	// A3: Visibility-aware methods
	GetByIDWithVisibility(ctx context.Context, id int64, userID int64, isAdmin bool) (*model.Post, error)
	ListByUserIDWithVisibility(ctx context.Context, userID, viewerID int64, isAdmin bool, offset, limit int) ([]*model.Post, error)
	ListAllForAdmin(ctx context.Context, offset, limit int) ([]*model.Post, error)
	// A5: Metrics
	GetDailyNewPosts(ctx context.Context) (int64, error)
}

// PostService handles post operations
type PostService struct {
	postRepo        postRepositoryBase
	hashtagRepo     repository.HashtagRepository
	postHashtagRepo repository.PostHashtagRepository
	postMediaRepo   repository.PostMediaRepository
	searchEngine    SearchEngine
}

// NewPostService creates a new post service
func NewPostService(
	postRepo postRepositoryBase,
	hashtagRepo repository.HashtagRepository,
	postHashtagRepo repository.PostHashtagRepository,
	postMediaRepo repository.PostMediaRepository,
	searchEngine SearchEngine,
) *PostService {
	return &PostService{
		postRepo:        postRepo,
		hashtagRepo:     hashtagRepo,
		postHashtagRepo: postHashtagRepo,
		postMediaRepo:   postMediaRepo,
		searchEngine:    searchEngine,
	}
}

// Create creates a new post
func (s *PostService) Create(ctx context.Context, post *model.Post, mediaURLs []string) error {
	// A2: Validate media rules
	if err := validateMedia(post.PostType, mediaURLs); err != nil {
		return err
	}

	// Create post
	if err := s.postRepo.Create(ctx, post); err != nil {
		return fmt.Errorf("failed to create post: %w", err)
	}

	// A1: Persist media records
	for i, url := range mediaURLs {
		postMedia := &model.PostMedia{
			PostID:    post.ID,
			MediaURL:  url,
			MediaType: post.PostType,
			SortOrder: i,
		}
		if err := s.postMediaRepo.Create(ctx, postMedia); err != nil {
			return fmt.Errorf("failed to create post media: %w", err)
		}
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

	if s.searchEngine != nil {
		if err := s.searchEngine.IndexPost(ctx, post); err != nil {
			return fmt.Errorf("failed to index post in search engine: %w", err)
		}
	}

	return nil
}

// A2: validateMedia validates post media according to rules
func validateMedia(postType string, mediaURLs []string) error {
	switch postType {
	case "image":
		if len(mediaURLs) > 9 {
			return fmt.Errorf("image post can have at most 9 images, got %d", len(mediaURLs))
		}
	case "video":
		if len(mediaURLs) != 1 {
			return fmt.Errorf("video post must have exactly 1 video, got %d", len(mediaURLs))
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

	if s.searchEngine != nil {
		if err := s.searchEngine.DeletePost(ctx, id); err != nil {
			return fmt.Errorf("failed to delete post in search engine: %w", err)
		}
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

// ListByIDs lists posts by ids while preserving order
func (s *PostService) ListByIDs(ctx context.Context, ids []int64) ([]*model.Post, error) {
	posts, err := s.postRepo.ListByIDs(ctx, ids)
	if err != nil {
		return nil, fmt.Errorf("failed to list posts by ids: %w", err)
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

// CountByUserIDWithVisibility counts posts with visibility check
func (s *PostService) CountByUserIDWithVisibility(ctx context.Context, userID, viewerID int64, isAdmin bool) (int64, error) {
	count, err := s.postRepo.CountByUserIDWithVisibility(ctx, userID, viewerID, isAdmin)
	if err != nil {
		return 0, fmt.Errorf("failed to count posts: %w", err)
	}
	return count, nil
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

// A3: GetByIDWithVisibility gets a post with visibility check
func (s *PostService) GetByIDWithVisibility(ctx context.Context, id int64, userID int64, isAdmin bool) (*model.Post, error) {
	post, err := s.postRepo.GetByIDWithVisibility(ctx, id, userID, isAdmin)
	if err != nil {
		return nil, fmt.Errorf("failed to get post: %w", err)
	}
	return post, nil
}

// A3: ListByUserIDWithVisibility lists posts with visibility check
func (s *PostService) ListByUserIDWithVisibility(ctx context.Context, userID, viewerID int64, isAdmin bool, offset, limit int) ([]*model.Post, error) {
	posts, err := s.postRepo.ListByUserIDWithVisibility(ctx, userID, viewerID, isAdmin, offset, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to list posts: %w", err)
	}
	return posts, nil
}

// A5: GetDailyNewPosts gets the count of new posts in the last 24 hours
func (s *PostService) GetDailyNewPosts(ctx context.Context) (int64, error) {
	count, err := s.postRepo.GetDailyNewPosts(ctx)
	if err != nil {
		return 0, fmt.Errorf("failed to get daily new posts: %w", err)
	}
	return count, nil
}

// A3: ListAllForAdmin lists all posts for admin (no visibility filter)
func (s *PostService) ListAllForAdmin(ctx context.Context, offset, limit int) ([]*model.Post, error) {
	posts, err := s.postRepo.ListAllForAdmin(ctx, offset, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to list all posts for admin: %w", err)
	}
	return posts, nil
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
