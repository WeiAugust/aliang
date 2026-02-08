package handler

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"

	"github.com/WeiAugust/aliang/backend/internal/model"
)

type mockSearchHandlerService struct {
	searchPostsFunc      func(ctx context.Context, query string, offset, limit int) ([]*model.Post, error)
	trendingHashtagsFunc func(ctx context.Context, limit int) ([]*model.Hashtag, error)
	postsByHashtagFunc   func(ctx context.Context, name string, offset, limit int) ([]*model.Post, error)
}

func (m *mockSearchHandlerService) SearchPosts(ctx context.Context, query string, offset, limit int) ([]*model.Post, error) {
	if m.searchPostsFunc == nil {
		return []*model.Post{}, nil
	}
	return m.searchPostsFunc(ctx, query, offset, limit)
}

func (m *mockSearchHandlerService) GetTrendingHashtags(ctx context.Context, limit int) ([]*model.Hashtag, error) {
	if m.trendingHashtagsFunc == nil {
		return []*model.Hashtag{}, nil
	}
	return m.trendingHashtagsFunc(ctx, limit)
}

func (m *mockSearchHandlerService) GetPostsByHashtag(ctx context.Context, name string, offset, limit int) ([]*model.Post, error) {
	if m.postsByHashtagFunc == nil {
		return []*model.Post{}, nil
	}
	return m.postsByHashtagFunc(ctx, name, offset, limit)
}

func TestSearchHandler_SearchPostsValidation(t *testing.T) {
	gin.SetMode(gin.TestMode)
	h := NewSearchHandler(&mockSearchHandlerService{})

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest(http.MethodGet, "/search", nil)

	h.SearchPosts(c)

	assert.Equal(t, http.StatusBadRequest, w.Code)
	assert.Contains(t, w.Body.String(), "Query parameter 'q' is required")
}

func TestSearchHandler_SearchPostsSuccess(t *testing.T) {
	gin.SetMode(gin.TestMode)
	h := NewSearchHandler(&mockSearchHandlerService{
		searchPostsFunc: func(_ context.Context, query string, offset, limit int) ([]*model.Post, error) {
			assert.Equal(t, "go", query)
			assert.Equal(t, 0, offset)
			assert.Equal(t, 20, limit)
			return []*model.Post{{ID: 1}}, nil
		},
	})

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest(http.MethodGet, "/search?q=go", nil)

	h.SearchPosts(c)

	assert.Equal(t, http.StatusOK, w.Code)
	assert.Contains(t, w.Body.String(), `"has_more":false`)
}

func TestSearchHandler_GetTrendingHashtagsError(t *testing.T) {
	gin.SetMode(gin.TestMode)
	h := NewSearchHandler(&mockSearchHandlerService{
		trendingHashtagsFunc: func(_ context.Context, _ int) ([]*model.Hashtag, error) {
			return nil, errors.New("db")
		},
	})

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest(http.MethodGet, "/hashtags/trending", nil)

	h.GetTrendingHashtags(c)

	assert.Equal(t, http.StatusInternalServerError, w.Code)
}

func TestSearchHandler_GetPostsByHashtagSuccess(t *testing.T) {
	gin.SetMode(gin.TestMode)
	h := NewSearchHandler(&mockSearchHandlerService{
		postsByHashtagFunc: func(_ context.Context, name string, offset, limit int) ([]*model.Post, error) {
			assert.Equal(t, "go", name)
			assert.Equal(t, 0, offset)
			assert.Equal(t, 20, limit)
			return []*model.Post{{ID: 1}, {ID: 2}}, nil
		},
	})

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Params = []gin.Param{{Key: "name", Value: "go"}}
	c.Request = httptest.NewRequest(http.MethodGet, "/hashtags/go/posts", nil)

	h.GetPostsByHashtag(c)

	assert.Equal(t, http.StatusOK, w.Code)
	assert.Contains(t, w.Body.String(), `"has_more":false`)
}
