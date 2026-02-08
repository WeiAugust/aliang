package service

import (
	"context"
	"errors"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/WeiAugust/aliang/backend/internal/model"
)

type mockPostRepo struct {
	createFunc                      func(ctx context.Context, post *model.Post) error
	getByIDFunc                     func(ctx context.Context, id int64) (*model.Post, error)
	updateFunc                      func(ctx context.Context, post *model.Post) error
	deleteFunc                      func(ctx context.Context, id int64) error
	listFunc                        func(ctx context.Context, offset, limit int) ([]*model.Post, error)
	listByIDsFunc                   func(ctx context.Context, ids []int64) ([]*model.Post, error)
	listByUserIDFunc                func(ctx context.Context, userID int64, offset, limit int) ([]*model.Post, error)
	countByUserIDWithVisibilityFunc func(ctx context.Context, userID, viewerID int64, isAdmin bool) (int64, error)
	searchFunc                      func(ctx context.Context, query string, offset, limit int) ([]*model.Post, error)
	countFunc                       func(ctx context.Context) (int64, error)
}

func (m *mockPostRepo) Create(ctx context.Context, post *model.Post) error {
	if m.createFunc == nil {
		return nil
	}
	return m.createFunc(ctx, post)
}

func (m *mockPostRepo) GetByID(ctx context.Context, id int64) (*model.Post, error) {
	if m.getByIDFunc == nil {
		return &model.Post{ID: id}, nil
	}
	return m.getByIDFunc(ctx, id)
}

func (m *mockPostRepo) Update(ctx context.Context, post *model.Post) error {
	if m.updateFunc == nil {
		return nil
	}
	return m.updateFunc(ctx, post)
}

func (m *mockPostRepo) Delete(ctx context.Context, id int64) error {
	if m.deleteFunc == nil {
		return nil
	}
	return m.deleteFunc(ctx, id)
}

func (m *mockPostRepo) List(ctx context.Context, offset, limit int) ([]*model.Post, error) {
	if m.listFunc == nil {
		return []*model.Post{}, nil
	}
	return m.listFunc(ctx, offset, limit)
}

func (m *mockPostRepo) ListByIDs(ctx context.Context, ids []int64) ([]*model.Post, error) {
	if m.listByIDsFunc == nil {
		return []*model.Post{}, nil
	}
	return m.listByIDsFunc(ctx, ids)
}

func (m *mockPostRepo) ListByUserID(ctx context.Context, userID int64, offset, limit int) ([]*model.Post, error) {
	if m.listByUserIDFunc == nil {
		return []*model.Post{}, nil
	}
	return m.listByUserIDFunc(ctx, userID, offset, limit)
}

func (m *mockPostRepo) CountByUserIDWithVisibility(ctx context.Context, userID, viewerID int64, isAdmin bool) (int64, error) {
	if m.countByUserIDWithVisibilityFunc == nil {
		return 0, nil
	}
	return m.countByUserIDWithVisibilityFunc(ctx, userID, viewerID, isAdmin)
}

func (m *mockPostRepo) Search(ctx context.Context, query string, offset, limit int) ([]*model.Post, error) {
	if m.searchFunc == nil {
		return []*model.Post{}, nil
	}
	return m.searchFunc(ctx, query, offset, limit)
}

func (m *mockPostRepo) Count(ctx context.Context) (int64, error) {
	if m.countFunc == nil {
		return 0, nil
	}
	return m.countFunc(ctx)
}

func (m *mockPostRepo) IncrementLikeCount(_ context.Context, _ int64) error {
	return errors.New("not implemented")
}
func (m *mockPostRepo) DecrementLikeCount(_ context.Context, _ int64) error {
	return errors.New("not implemented")
}
func (m *mockPostRepo) IncrementCommentCount(_ context.Context, _ int64) error {
	return errors.New("not implemented")
}
func (m *mockPostRepo) DecrementCommentCount(_ context.Context, _ int64) error {
	return errors.New("not implemented")
}

// A3: GetByIDWithVisibility mock
func (m *mockPostRepo) GetByIDWithVisibility(ctx context.Context, id int64, userID int64, isAdmin bool) (*model.Post, error) {
	if m.getByIDFunc == nil {
		return &model.Post{ID: id}, nil
	}
	return m.getByIDFunc(ctx, id)
}

// A3: ListByUserIDWithVisibility mock
func (m *mockPostRepo) ListByUserIDWithVisibility(ctx context.Context, userID int64, viewerID int64, isAdmin bool, offset, limit int) ([]*model.Post, error) {
	if m.listFunc == nil {
		return []*model.Post{}, nil
	}
	return m.listFunc(ctx, offset, limit)
}

// A3: ListAllForAdmin mock
func (m *mockPostRepo) ListAllForAdmin(ctx context.Context, offset, limit int) ([]*model.Post, error) {
	if m.listFunc == nil {
		return []*model.Post{}, nil
	}
	return m.listFunc(ctx, offset, limit)
}

// A5: GetDailyNewPosts mock
func (m *mockPostRepo) GetDailyNewPosts(ctx context.Context) (int64, error) {
	if m.countFunc == nil {
		return 0, nil
	}
	return m.countFunc(ctx)
}

type mockHashtagRepo struct {
	getOrCreateFunc        func(ctx context.Context, name string) (*model.Hashtag, error)
	incrementPostCountFunc func(ctx context.Context, id int64) error
	decrementPostCountFunc func(ctx context.Context, id int64) error
}

func (m *mockHashtagRepo) Create(_ context.Context, _ *model.Hashtag) error {
	return errors.New("not implemented")
}

func (m *mockHashtagRepo) GetByName(_ context.Context, _ string) (*model.Hashtag, error) {
	return nil, errors.New("not implemented")
}

func (m *mockHashtagRepo) GetOrCreate(ctx context.Context, name string) (*model.Hashtag, error) {
	if m.getOrCreateFunc == nil {
		return &model.Hashtag{ID: 1, Name: name}, nil
	}
	return m.getOrCreateFunc(ctx, name)
}

func (m *mockHashtagRepo) IncrementPostCount(ctx context.Context, id int64) error {
	if m.incrementPostCountFunc == nil {
		return nil
	}
	return m.incrementPostCountFunc(ctx, id)
}

func (m *mockHashtagRepo) DecrementPostCount(ctx context.Context, id int64) error {
	if m.decrementPostCountFunc == nil {
		return nil
	}
	return m.decrementPostCountFunc(ctx, id)
}

func (m *mockHashtagRepo) ListTrending(_ context.Context, _ int) ([]*model.Hashtag, error) {
	return nil, errors.New("not implemented")
}

type mockPostHashtagRepo struct {
	createFunc               func(ctx context.Context, postID, hashtagID int64) error
	deleteByPostIDFunc       func(ctx context.Context, postID int64) error
	listHashtagsByPostIDFunc func(ctx context.Context, postID int64) ([]*model.Hashtag, error)
}

func (m *mockPostHashtagRepo) Create(ctx context.Context, postID, hashtagID int64) error {
	if m.createFunc == nil {
		return nil
	}
	return m.createFunc(ctx, postID, hashtagID)
}

func (m *mockPostHashtagRepo) DeleteByPostID(ctx context.Context, postID int64) error {
	if m.deleteByPostIDFunc == nil {
		return nil
	}
	return m.deleteByPostIDFunc(ctx, postID)
}

func (m *mockPostHashtagRepo) ListHashtagsByPostID(ctx context.Context, postID int64) ([]*model.Hashtag, error) {
	if m.listHashtagsByPostIDFunc == nil {
		return []*model.Hashtag{}, nil
	}
	return m.listHashtagsByPostIDFunc(ctx, postID)
}

func (m *mockPostHashtagRepo) ListPostsByHashtagID(_ context.Context, _ int64, _, _ int) ([]*model.Post, error) {
	return nil, errors.New("not implemented")
}

type mockPostMediaRepo struct {
	createFunc func(ctx context.Context, postMedia *model.PostMedia) error
}

func (m *mockPostMediaRepo) Create(ctx context.Context, postMedia *model.PostMedia) error {
	if m.createFunc == nil {
		return nil
	}
	return m.createFunc(ctx, postMedia)
}

func (m *mockPostMediaRepo) DeleteByPostID(_ context.Context, _ int64) error {
	return nil
}

func (m *mockPostMediaRepo) ListByPostID(_ context.Context, _ int64) ([]*model.PostMedia, error) {
	return nil, nil
}

type mockPostSearchEngine struct {
	indexPostFunc  func(ctx context.Context, post *model.Post) error
	deletePostFunc func(ctx context.Context, postID int64) error
}

func (m *mockPostSearchEngine) EnsureIndex(_ context.Context) error {
	return nil
}

func (m *mockPostSearchEngine) IndexPost(ctx context.Context, post *model.Post) error {
	if m.indexPostFunc == nil {
		return nil
	}
	return m.indexPostFunc(ctx, post)
}

func (m *mockPostSearchEngine) DeletePost(ctx context.Context, postID int64) error {
	if m.deletePostFunc == nil {
		return nil
	}
	return m.deletePostFunc(ctx, postID)
}

func (m *mockPostSearchEngine) SearchPostIDs(_ context.Context, _ string, _, _ int) ([]int64, error) {
	return nil, nil
}

func TestPostService_CreateWithHashtags(t *testing.T) {
	var gotTags []string
	var relCount int

	svc := NewPostService(
		&mockPostRepo{
			createFunc: func(_ context.Context, post *model.Post) error {
				post.ID = 10
				return nil
			},
		},
		&mockHashtagRepo{
			getOrCreateFunc: func(_ context.Context, name string) (*model.Hashtag, error) {
				gotTags = append(gotTags, name)
				if name == "golang" {
					return &model.Hashtag{ID: 1, Name: name}, nil
				}
				return &model.Hashtag{ID: 2, Name: name}, nil
			},
		},
		&mockPostHashtagRepo{
			createFunc: func(_ context.Context, postID, hashtagID int64) error {
				assert.Equal(t, int64(10), postID)
				assert.True(t, hashtagID == 1 || hashtagID == 2)
				relCount++
				return nil
			},
		},
		&mockPostMediaRepo{},
		nil,
	)

	post := &model.Post{Content: "#GoLang hi #test #golang"}
	err := svc.Create(context.Background(), post, []string{})
	require.NoError(t, err)
	assert.ElementsMatch(t, []string{"golang", "test"}, gotTags)
	assert.Equal(t, 2, relCount)
}

func TestPostService_CountByUserIDWithVisibility(t *testing.T) {
	svc := NewPostService(
		&mockPostRepo{
			countByUserIDWithVisibilityFunc: func(_ context.Context, userID, viewerID int64, isAdmin bool) (int64, error) {
				assert.Equal(t, int64(10), userID)
				assert.Equal(t, int64(20), viewerID)
				assert.False(t, isAdmin)
				return 7, nil
			},
		},
		&mockHashtagRepo{},
		&mockPostHashtagRepo{},
		&mockPostMediaRepo{},
		nil,
	)

	count, err := svc.CountByUserIDWithVisibility(context.Background(), 10, 20, false)
	require.NoError(t, err)
	assert.Equal(t, int64(7), count)
}

func TestPostService_CreateError(t *testing.T) {
	svc := NewPostService(
		&mockPostRepo{
			createFunc: func(_ context.Context, _ *model.Post) error {
				return errors.New("db down")
			},
		},
		&mockHashtagRepo{},
		&mockPostHashtagRepo{},
		&mockPostMediaRepo{},
		nil,
	)

	err := svc.Create(context.Background(), &model.Post{Content: "content"}, []string{})
	require.Error(t, err)
	assert.Contains(t, err.Error(), "failed to create post")
}

func TestPostService_Delete(t *testing.T) {
	svc := NewPostService(
		&mockPostRepo{
			getByIDFunc: func(_ context.Context, id int64) (*model.Post, error) {
				return &model.Post{ID: id}, nil
			},
			deleteFunc: func(_ context.Context, id int64) error {
				assert.Equal(t, int64(99), id)
				return nil
			},
		},
		&mockHashtagRepo{},
		&mockPostHashtagRepo{
			listHashtagsByPostIDFunc: func(_ context.Context, postID int64) ([]*model.Hashtag, error) {
				assert.Equal(t, int64(99), postID)
				return []*model.Hashtag{{ID: 1}, {ID: 2}}, nil
			},
			deleteByPostIDFunc: func(_ context.Context, postID int64) error {
				assert.Equal(t, int64(99), postID)
				return nil
			},
		},
		&mockPostMediaRepo{},
		nil,
	)

	err := svc.Delete(context.Background(), 99)
	require.NoError(t, err)
}

func TestExtractHashtags(t *testing.T) {
	tags := extractHashtags("hello #Go #go #Test_1 #中文 #go")
	assert.ElementsMatch(t, []string{"go", "test_1"}, tags)
}

func TestPostService_ListByIDs(t *testing.T) {
	svc := NewPostService(
		&mockPostRepo{
			listByIDsFunc: func(_ context.Context, ids []int64) ([]*model.Post, error) {
				assert.Equal(t, []int64{4, 2}, ids)
				return []*model.Post{{ID: 4}, {ID: 2}}, nil
			},
		},
		&mockHashtagRepo{},
		&mockPostHashtagRepo{},
		&mockPostMediaRepo{},
		nil,
	)

	posts, err := svc.ListByIDs(context.Background(), []int64{4, 2})
	require.NoError(t, err)
	assert.Len(t, posts, 2)
	assert.Equal(t, int64(4), posts[0].ID)
	assert.Equal(t, int64(2), posts[1].ID)
}

func TestPostService_CreateIndexesIntoSearchEngine(t *testing.T) {
	indexed := false

	svc := NewPostService(
		&mockPostRepo{
			createFunc: func(_ context.Context, post *model.Post) error {
				post.ID = 77
				return nil
			},
		},
		&mockHashtagRepo{},
		&mockPostHashtagRepo{},
		&mockPostMediaRepo{},
		&mockPostSearchEngine{
			indexPostFunc: func(_ context.Context, post *model.Post) error {
				indexed = true
				assert.Equal(t, int64(77), post.ID)
				return nil
			},
		},
	)

	err := svc.Create(context.Background(), &model.Post{Content: "hello", PostType: "image"}, []string{})
	require.NoError(t, err)
	assert.True(t, indexed)
}

func TestPostService_CreateSearchEngineError(t *testing.T) {
	svc := NewPostService(
		&mockPostRepo{
			createFunc: func(_ context.Context, post *model.Post) error {
				post.ID = 55
				return nil
			},
		},
		&mockHashtagRepo{},
		&mockPostHashtagRepo{},
		&mockPostMediaRepo{},
		&mockPostSearchEngine{
			indexPostFunc: func(_ context.Context, _ *model.Post) error {
				return errors.New("es unavailable")
			},
		},
	)

	err := svc.Create(context.Background(), &model.Post{Content: "hello", PostType: "image"}, []string{})
	require.Error(t, err)
	assert.Contains(t, err.Error(), "failed to index post in search engine")
}

func TestPostService_DeleteRemovesFromSearchEngine(t *testing.T) {
	deleted := false

	svc := NewPostService(
		&mockPostRepo{
			getByIDFunc: func(_ context.Context, id int64) (*model.Post, error) {
				return &model.Post{ID: id}, nil
			},
			deleteFunc: func(_ context.Context, id int64) error {
				assert.Equal(t, int64(99), id)
				return nil
			},
		},
		&mockHashtagRepo{},
		&mockPostHashtagRepo{},
		&mockPostMediaRepo{},
		&mockPostSearchEngine{
			deletePostFunc: func(_ context.Context, postID int64) error {
				deleted = true
				assert.Equal(t, int64(99), postID)
				return nil
			},
		},
	)

	err := svc.Delete(context.Background(), 99)
	require.NoError(t, err)
	assert.True(t, deleted)
}

func TestPostService_DeleteSearchEngineError(t *testing.T) {
	svc := NewPostService(
		&mockPostRepo{
			getByIDFunc: func(_ context.Context, id int64) (*model.Post, error) {
				return &model.Post{ID: id}, nil
			},
			deleteFunc: func(_ context.Context, _ int64) error {
				return nil
			},
		},
		&mockHashtagRepo{},
		&mockPostHashtagRepo{},
		&mockPostMediaRepo{},
		&mockPostSearchEngine{
			deletePostFunc: func(_ context.Context, _ int64) error {
				return errors.New("es unavailable")
			},
		},
	)

	err := svc.Delete(context.Background(), 99)
	require.Error(t, err)
	assert.Contains(t, err.Error(), "failed to delete post in search engine")
}
