package service

import (
	"context"
	"fmt"
	"strings"

	"go.uber.org/zap"

	"github.com/WeiAugust/aliang/backend/internal/model"
	"github.com/WeiAugust/aliang/backend/internal/repository"
)

type searchablePostRepo interface {
	ListByIDs(ctx context.Context, ids []int64) ([]*model.Post, error)
	Search(ctx context.Context, query string, offset, limit int) ([]*model.Post, error)
}

// SearchService handles search operations
type SearchService struct {
	postRepo        searchablePostRepo
	hashtagRepo     repository.HashtagRepository
	postHashtagRepo repository.PostHashtagRepository
	searchEngine    SearchEngine
	logger          *zap.Logger
}

// NewSearchService creates a new search service
func NewSearchService(
	postRepo searchablePostRepo,
	hashtagRepo repository.HashtagRepository,
	postHashtagRepo repository.PostHashtagRepository,
	searchEngine SearchEngine,
	logger *zap.Logger,
) *SearchService {
	if logger == nil {
		logger = zap.NewNop()
	}

	return &SearchService{
		postRepo:        postRepo,
		hashtagRepo:     hashtagRepo,
		postHashtagRepo: postHashtagRepo,
		searchEngine:    searchEngine,
		logger:          logger,
	}
}

// SearchPosts searches posts by query
func (s *SearchService) SearchPosts(ctx context.Context, query string, offset, limit int) ([]*model.Post, error) {
	trimmedQuery := strings.TrimSpace(query)
	if s.searchEngine != nil && trimmedQuery != "" {
		ids, err := s.searchEngine.SearchPostIDs(ctx, trimmedQuery, offset, limit)
		if err == nil {
			if len(ids) == 0 {
				return []*model.Post{}, nil
			}

			posts, listErr := s.postRepo.ListByIDs(ctx, ids)
			if listErr == nil {
				if len(posts) == 0 {
					return posts, nil
				}

				filtered := make([]*model.Post, 0, len(posts))
				for _, post := range posts {
					if (post.Visibility == "" || post.Visibility == "public") && post.DeletedAt == nil {
						filtered = append(filtered, post)
					}
				}

				if len(filtered) == 0 {
					return []*model.Post{}, nil
				}

				return filtered, nil
			}

			s.logger.Warn("Elasticsearch ids lookup failed, fallback to database search", zap.Error(listErr))
		} else {
			s.logger.Warn("Elasticsearch search failed, fallback to database search", zap.Error(err))
		}
	}

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
