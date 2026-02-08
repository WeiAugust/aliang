package handler

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/WeiAugust/aliang/backend/internal/model"
)

type mockPostHandlerService struct {
	createFunc                  func(ctx context.Context, post *model.Post, mediaURLs []string) error
	listFunc                    func(ctx context.Context, offset, limit int) ([]*model.Post, error)
	getByIDFunc                 func(ctx context.Context, id int64) (*model.Post, error)
	deleteFunc                  func(ctx context.Context, id int64) error
	getByIDWithVisibilityFunc   func(ctx context.Context, id int64, userID int64, isAdmin bool) (*model.Post, error)
	listByUserIDWithVisibilityFunc func(ctx context.Context, userID, viewerID int64, isAdmin bool, offset, limit int) ([]*model.Post, error)
	listAllForAdminFunc         func(ctx context.Context, offset, limit int) ([]*model.Post, error)
	getDailyNewPostsFunc        func(ctx context.Context) (int64, error)
}

func (m *mockPostHandlerService) Create(ctx context.Context, post *model.Post, mediaURLs []string) error {
	if m.createFunc == nil {
		return nil
	}
	return m.createFunc(ctx, post, mediaURLs)
}

func (m *mockPostHandlerService) List(ctx context.Context, offset, limit int) ([]*model.Post, error) {
	if m.listFunc == nil {
		return []*model.Post{}, nil
	}
	return m.listFunc(ctx, offset, limit)
}

func (m *mockPostHandlerService) GetByID(ctx context.Context, id int64) (*model.Post, error) {
	if m.getByIDFunc == nil {
		return &model.Post{ID: id, UserID: 1}, nil
	}
	return m.getByIDFunc(ctx, id)
}

func (m *mockPostHandlerService) Delete(ctx context.Context, id int64) error {
	if m.deleteFunc == nil {
		return nil
	}
	return m.deleteFunc(ctx, id)
}

// A3: GetByIDWithVisibility mock
func (m *mockPostHandlerService) GetByIDWithVisibility(ctx context.Context, id int64, userID int64, isAdmin bool) (*model.Post, error) {
	if m.getByIDWithVisibilityFunc == nil {
		return &model.Post{ID: id, UserID: userID}, nil
	}
	return m.getByIDWithVisibilityFunc(ctx, id, userID, isAdmin)
}

// A3: ListByUserIDWithVisibility mock
func (m *mockPostHandlerService) ListByUserIDWithVisibility(ctx context.Context, userID, viewerID int64, isAdmin bool, offset, limit int) ([]*model.Post, error) {
	if m.listByUserIDWithVisibilityFunc == nil {
		return []*model.Post{}, nil
	}
	return m.listByUserIDWithVisibilityFunc(ctx, userID, viewerID, isAdmin, offset, limit)
}

// A3: ListAllForAdmin mock
func (m *mockPostHandlerService) ListAllForAdmin(ctx context.Context, offset, limit int) ([]*model.Post, error) {
	if m.listAllForAdminFunc == nil {
		return []*model.Post{}, nil
	}
	return m.listAllForAdminFunc(ctx, offset, limit)
}

// A5: GetDailyNewPosts mock
func (m *mockPostHandlerService) GetDailyNewPosts(ctx context.Context) (int64, error) {
	if m.getDailyNewPostsFunc == nil {
		return 0, nil
	}
	return m.getDailyNewPostsFunc(ctx)
}

type mockPostLikeChecker struct{}

func (m *mockPostLikeChecker) BatchIsLiked(_ context.Context, _ int64, postIDs []int64) (map[int64]bool, error) {
	result := make(map[int64]bool, len(postIDs))
	for _, id := range postIDs {
		result[id] = false
	}
	return result, nil
}

func (m *mockPostLikeChecker) IsLiked(_ context.Context, _, _ int64) (bool, error) {
	return false, nil
}

func TestPostHandler_GetPosts(t *testing.T) {
	gin.SetMode(gin.TestMode)

	h := NewPostHandler(&mockPostHandlerService{
		listFunc: func(_ context.Context, offset, limit int) ([]*model.Post, error) {
			assert.Equal(t, 0, offset)
			assert.Equal(t, 20, limit)
			return []*model.Post{{ID: 1}, {ID: 2}}, nil
		},
	}, &mockPostLikeChecker{})

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest(http.MethodGet, "/posts", nil)

	h.GetPosts(c)

	assert.Equal(t, http.StatusOK, w.Code)
	assert.Contains(t, w.Body.String(), `"has_more":false`)
}

func TestPostHandler_CreatePostUnauthorized(t *testing.T) {
	gin.SetMode(gin.TestMode)
	h := NewPostHandler(&mockPostHandlerService{}, &mockPostLikeChecker{})

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest(http.MethodPost, "/posts", strings.NewReader(`{"title":"t","content":"c","post_type":"image"}`))
	c.Request.Header.Set("Content-Type", "application/json")

	h.CreatePost(c)

	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestPostHandler_DeletePostForbidden(t *testing.T) {
	gin.SetMode(gin.TestMode)

	h := NewPostHandler(&mockPostHandlerService{
		getByIDFunc: func(_ context.Context, id int64) (*model.Post, error) {
			return &model.Post{ID: id, UserID: 2}, nil
		},
	}, &mockPostLikeChecker{})

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Params = []gin.Param{{Key: "id", Value: "1"}}
	c.Set("user_id", int64(1))
	c.Request = httptest.NewRequest(http.MethodDelete, "/posts/1", nil)

	h.DeletePost(c)

	assert.Equal(t, http.StatusForbidden, w.Code)
	assert.Contains(t, w.Body.String(), "You can only delete your own posts")
}

func TestPostHandler_GetPostNotFound(t *testing.T) {
	gin.SetMode(gin.TestMode)

	h := NewPostHandler(&mockPostHandlerService{
		getByIDWithVisibilityFunc: func(_ context.Context, _ int64, _ int64, _ bool) (*model.Post, error) {
			return nil, errors.New("not found")
		},
	}, &mockPostLikeChecker{})

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Params = []gin.Param{{Key: "id", Value: "1"}}
	c.Request = httptest.NewRequest(http.MethodGet, "/posts/1", nil)

	h.GetPost(c)

	assert.Equal(t, http.StatusNotFound, w.Code)
}

func TestPostHandler_CreatePostSuccess(t *testing.T) {
	gin.SetMode(gin.TestMode)

	h := NewPostHandler(&mockPostHandlerService{
		createFunc: func(_ context.Context, post *model.Post, _ []string) error {
			post.ID = 88
			return nil
		},
	}, &mockPostLikeChecker{})

	body := `{"title":"t","content":"c","post_type":"image"}`
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Set("user_id", int64(5))
	c.Request = httptest.NewRequest(http.MethodPost, "/posts", strings.NewReader(body))
	c.Request.Header.Set("Content-Type", "application/json")

	h.CreatePost(c)

	assert.Equal(t, http.StatusCreated, w.Code)
	var resp map[string]any
	require.NoError(t, json.Unmarshal(w.Body.Bytes(), &resp))
	assert.Equal(t, true, resp["success"])
}
