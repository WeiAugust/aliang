package service

import (
	"context"
	"fmt"

	"github.com/WeiAugust/aliang/backend/internal/model"
	"github.com/WeiAugust/aliang/backend/internal/repository"
)

type searchablePostRepo interface {
	Search(ctx context.Context, query string, offset, limit int) ([]*model.Post, error)
}

// SearchService handles search operations
type SearchService struct {
	postRepo        searchablePostRepo
	hashtagRepo     repository.HashtagRepository
	postHashtagRepo repository.PostHashtagRepository
}

// NewSearchService creates a new search service
func NewSearchService(
	postRepo searchablePostRepo,
	hashtagRepo repository.HashtagRepository,
	postHashtagRepo repository.PostHashtagRepository,
) *SearchService {
	return &SearchService{
		postRepo:        postRepo,
		hashtagRepo:     hashtagRepo,
		postHashtagRepo: postHashtagRepo,
	}
}

// SearchPosts searches posts by query
func (s *SearchService) SearchPosts(ctx context.Context, query string, offset, limit int) ([]*model.Post, error) {
	posts, err := s.postRepo.Search(ctx, query, offset, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to search posts: %w", err)
	}
	return posts, nil
}

// GetTrendingHashtags gets trending hashtags
func (s *SearchService) GetTrendingHashtags(ctx context.Context, limit int) ([]*model.Hashtag, error) {
	hashtags, err := s.hashtagRepo.ListTrending(ctx, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to get trending hashtags: %w", err)
	}
	return hashtags, nil
}

// GetPostsByHashtag gets posts by hashtag name
func (s *SearchService) GetPostsByHashtag(ctx context.Context, name string, offset, limit int) ([]*model.Post, error) {
	// Get hashtag by name
	hashtag, err := s.hashtagRepo.GetByName(ctx, name)
	if err != nil {
		return nil, fmt.Errorf("failed to get hashtag: %w", err)
	}

	// Get posts by hashtag ID
	posts, err := s.postHashtagRepo.ListPostsByHashtagID(ctx, hashtag.ID, offset, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to get posts by hashtag: %w", err)
	}

	return posts, nil
}
