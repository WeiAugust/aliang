package service

import (
	"context"
	"errors"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/WeiAugust/aliang/backend/internal/model"
)

type mockSearchPostRepo struct {
	listByIDsFunc func(ctx context.Context, ids []int64) ([]*model.Post, error)
	searchFunc    func(ctx context.Context, query string, offset, limit int) ([]*model.Post, error)
}

func (m *mockSearchPostRepo) ListByIDs(ctx context.Context, ids []int64) ([]*model.Post, error) {
	if m.listByIDsFunc == nil {
		return []*model.Post{}, nil
	}
	return m.listByIDsFunc(ctx, ids)
}

func (m *mockSearchPostRepo) Search(ctx context.Context, query string, offset, limit int) ([]*model.Post, error) {
	if m.searchFunc == nil {
		return []*model.Post{}, nil
	}
	return m.searchFunc(ctx, query, offset, limit)
}

type mockSearchHashtagRepo struct {
	getByNameFunc    func(ctx context.Context, name string) (*model.Hashtag, error)
	listTrendingFunc func(ctx context.Context, limit int) ([]*model.Hashtag, error)
}

func (m *mockSearchHashtagRepo) Create(_ context.Context, _ *model.Hashtag) error {
	return errors.New("not implemented")
}

func (m *mockSearchHashtagRepo) GetByName(ctx context.Context, name string) (*model.Hashtag, error) {
	if m.getByNameFunc == nil {
		return &model.Hashtag{ID: 1, Name: name}, nil
	}
	return m.getByNameFunc(ctx, name)
}

func (m *mockSearchHashtagRepo) GetOrCreate(_ context.Context, _ string) (*model.Hashtag, error) {
	return nil, errors.New("not implemented")
}

func (m *mockSearchHashtagRepo) IncrementPostCount(_ context.Context, _ int64) error {
	return errors.New("not implemented")
}

func (m *mockSearchHashtagRepo) DecrementPostCount(_ context.Context, _ int64) error {
	return errors.New("not implemented")
}

func (m *mockSearchHashtagRepo) ListTrending(ctx context.Context, limit int) ([]*model.Hashtag, error) {
	if m.listTrendingFunc == nil {
		return []*model.Hashtag{}, nil
	}
	return m.listTrendingFunc(ctx, limit)
}

type mockSearchPostHashtagRepo struct {
	listPostsByHashtagIDFunc func(ctx context.Context, hashtagID int64, offset, limit int) ([]*model.Post, error)
}

type mockSearchEngine struct {
	searchPostIDsFunc func(ctx context.Context, query string, offset, limit int) ([]int64, error)
}

func (m *mockSearchEngine) EnsureIndex(_ context.Context) error {
	return nil
}

func (m *mockSearchEngine) IndexPost(_ context.Context, _ *model.Post) error {
	return nil
}

func (m *mockSearchEngine) DeletePost(_ context.Context, _ int64) error {
	return nil
}

func (m *mockSearchEngine) SearchPostIDs(ctx context.Context, query string, offset, limit int) ([]int64, error) {
	if m.searchPostIDsFunc == nil {
		return nil, nil
	}
	return m.searchPostIDsFunc(ctx, query, offset, limit)
}

func (m *mockSearchPostHashtagRepo) Create(_ context.Context, _, _ int64) error {
	return errors.New("not implemented")
}

func (m *mockSearchPostHashtagRepo) DeleteByPostID(_ context.Context, _ int64) error {
	return errors.New("not implemented")
}

func (m *mockSearchPostHashtagRepo) ListHashtagsByPostID(_ context.Context, _ int64) ([]*model.Hashtag, error) {
	return nil, errors.New("not implemented")
}

func (m *mockSearchPostHashtagRepo) ListPostsByHashtagID(ctx context.Context, hashtagID int64, offset, limit int) ([]*model.Post, error) {
	if m.listPostsByHashtagIDFunc == nil {
		return []*model.Post{}, nil
	}
	return m.listPostsByHashtagIDFunc(ctx, hashtagID, offset, limit)
}

func TestSearchService_SearchPosts(t *testing.T) {
	svc := NewSearchService(
		&mockSearchPostRepo{
			searchFunc: func(_ context.Context, query string, offset, limit int) ([]*model.Post, error) {
				assert.Equal(t, "go", query)
				assert.Equal(t, 0, offset)
				assert.Equal(t, 20, limit)
				return []*model.Post{{ID: 1, Title: "go"}}, nil
			},
		},
		&mockSearchHashtagRepo{},
		&mockSearchPostHashtagRepo{},
		nil,
		zap.NewNop(),
	)

	posts, err := svc.SearchPosts(context.Background(), "go", 0, 20)
	require.NoError(t, err)
	assert.Len(t, posts, 1)
}

func TestSearchService_GetTrendingHashtags(t *testing.T) {
	svc := NewSearchService(
		&mockSearchPostRepo{},
		&mockSearchHashtagRepo{
			listTrendingFunc: func(_ context.Context, limit int) ([]*model.Hashtag, error) {
				assert.Equal(t, 5, limit)
				return []*model.Hashtag{{ID: 1, Name: "go"}}, nil
			},
		},
		&mockSearchPostHashtagRepo{},
		nil,
		zap.NewNop(),
	)

	tags, err := svc.GetTrendingHashtags(context.Background(), 5)
	require.NoError(t, err)
	assert.Len(t, tags, 1)
}

func TestSearchService_GetPostsByHashtag(t *testing.T) {
	svc := NewSearchService(
		&mockSearchPostRepo{},
		&mockSearchHashtagRepo{
			getByNameFunc: func(_ context.Context, name string) (*model.Hashtag, error) {
				assert.Equal(t, "go", name)
				return &model.Hashtag{ID: 9, Name: name}, nil
			},
		},
		&mockSearchPostHashtagRepo{
			listPostsByHashtagIDFunc: func(_ context.Context, hashtagID int64, offset, limit int) ([]*model.Post, error) {
				assert.Equal(t, int64(9), hashtagID)
				assert.Equal(t, 10, offset)
				assert.Equal(t, 3, limit)
				return []*model.Post{{ID: 1}, {ID: 2}}, nil
			},
		},
		nil,
		zap.NewNop(),
	)

	posts, err := svc.GetPostsByHashtag(context.Background(), "go", 10, 3)
	require.NoError(t, err)
	assert.Len(t, posts, 2)
}

func TestSearchService_SearchPostsUsesSearchEngine(t *testing.T) {
	svc := NewSearchService(
		&mockSearchPostRepo{
			listByIDsFunc: func(_ context.Context, ids []int64) ([]*model.Post, error) {
				assert.Equal(t, []int64{3, 1}, ids)
				return []*model.Post{{ID: 3}, {ID: 1}}, nil
			},
			searchFunc: func(_ context.Context, _ string, _, _ int) ([]*model.Post, error) {
				t.Fatal("database fallback should not be called when search engine succeeds")
				return nil, nil
			},
		},
		&mockSearchHashtagRepo{},
		&mockSearchPostHashtagRepo{},
		&mockSearchEngine{
			searchPostIDsFunc: func(_ context.Context, query string, offset, limit int) ([]int64, error) {
				assert.Equal(t, "swift", query)
				assert.Equal(t, 2, offset)
				assert.Equal(t, 10, limit)
				return []int64{3, 1}, nil
			},
		},
		zap.NewNop(),
	)

	posts, err := svc.SearchPosts(context.Background(), "swift", 2, 10)
	require.NoError(t, err)
	assert.Len(t, posts, 2)
	assert.Equal(t, int64(3), posts[0].ID)
	assert.Equal(t, int64(1), posts[1].ID)
}

func TestSearchService_SearchPostsFallsBackWhenSearchEngineFails(t *testing.T) {
	svc := NewSearchService(
		&mockSearchPostRepo{
			searchFunc: func(_ context.Context, query string, offset, limit int) ([]*model.Post, error) {
				assert.Equal(t, "fallback", query)
				assert.Equal(t, 0, offset)
				assert.Equal(t, 20, limit)
				return []*model.Post{{ID: 9}}, nil
			},
		},
		&mockSearchHashtagRepo{},
		&mockSearchPostHashtagRepo{},
		&mockSearchEngine{
			searchPostIDsFunc: func(_ context.Context, _ string, _, _ int) ([]int64, error) {
				return nil, errors.New("es down")
			},
		},
		zap.NewNop(),
	)

	posts, err := svc.SearchPosts(context.Background(), "fallback", 0, 20)
	require.NoError(t, err)
	assert.Len(t, posts, 1)
	assert.Equal(t, int64(9), posts[0].ID)
}
