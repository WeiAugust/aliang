package handler

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"

	"github.com/WeiAugust/aliang/backend/internal/model"
)

type mockInteractionHandlerService struct {
	toggleLikeFunc    func(ctx context.Context, userID, postID int64) (bool, error)
	listCommentsFunc  func(ctx context.Context, postID int64, offset, limit int) ([]*model.Comment, error)
	createCommentFunc func(ctx context.Context, comment *model.Comment) error
	deleteCommentFunc func(ctx context.Context, id int64) error
}

func (m *mockInteractionHandlerService) ToggleLike(ctx context.Context, userID, postID int64) (bool, error) {
	if m.toggleLikeFunc == nil {
		return true, nil
	}
	return m.toggleLikeFunc(ctx, userID, postID)
}

func (m *mockInteractionHandlerService) ListComments(ctx context.Context, postID int64, offset, limit int) ([]*model.Comment, error) {
	if m.listCommentsFunc == nil {
		return []*model.Comment{}, nil
	}
	return m.listCommentsFunc(ctx, postID, offset, limit)
}

func (m *mockInteractionHandlerService) CreateComment(ctx context.Context, comment *model.Comment) error {
	if m.createCommentFunc == nil {
		return nil
	}
	return m.createCommentFunc(ctx, comment)
}

func (m *mockInteractionHandlerService) DeleteComment(ctx context.Context, id int64) error {
	if m.deleteCommentFunc == nil {
		return nil
	}
	return m.deleteCommentFunc(ctx, id)
}

func TestInteractionHandler_ToggleLikeUnauthorized(t *testing.T) {
	gin.SetMode(gin.TestMode)
	h := NewInteractionHandler(&mockInteractionHandlerService{})

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Params = []gin.Param{{Key: "id", Value: "1"}}
	c.Request = httptest.NewRequest(http.MethodPost, "/posts/1/like", nil)

	h.ToggleLike(c)

	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestInteractionHandler_ToggleLikeSuccess(t *testing.T) {
	gin.SetMode(gin.TestMode)
	h := NewInteractionHandler(&mockInteractionHandlerService{
		toggleLikeFunc: func(_ context.Context, userID, postID int64) (bool, error) {
			assert.Equal(t, int64(1), userID)
			assert.Equal(t, int64(2), postID)
			return false, nil
		},
	})

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Set("user_id", int64(1))
	c.Params = []gin.Param{{Key: "id", Value: "2"}}
	c.Request = httptest.NewRequest(http.MethodPost, "/posts/2/like", nil)

	h.ToggleLike(c)

	assert.Equal(t, http.StatusOK, w.Code)
	assert.Contains(t, w.Body.String(), `"is_liked":false`)
}

func TestInteractionHandler_CreateComment(t *testing.T) {
	gin.SetMode(gin.TestMode)
	h := NewInteractionHandler(&mockInteractionHandlerService{
		createCommentFunc: func(_ context.Context, comment *model.Comment) error {
			assert.Equal(t, int64(1), comment.UserID)
			assert.Equal(t, int64(2), comment.PostID)
			assert.Equal(t, "hello", comment.Content)
			return nil
		},
	})

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Set("user_id", int64(1))
	c.Params = []gin.Param{{Key: "id", Value: "2"}}
	c.Request = httptest.NewRequest(http.MethodPost, "/posts/2/comments", strings.NewReader(`{"content":"hello"}`))
	c.Request.Header.Set("Content-Type", "application/json")

	h.CreateComment(c)

	assert.Equal(t, http.StatusCreated, w.Code)
	assert.Contains(t, w.Body.String(), `"content":"hello"`)
}

func TestInteractionHandler_DeleteCommentError(t *testing.T) {
	gin.SetMode(gin.TestMode)
	h := NewInteractionHandler(&mockInteractionHandlerService{
		deleteCommentFunc: func(_ context.Context, _ int64) error {
			return errors.New("db err")
		},
	})

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Set("user_id", int64(1))
	c.Params = []gin.Param{{Key: "id", Value: "3"}}
	c.Request = httptest.NewRequest(http.MethodDelete, "/comments/3", nil)

	h.DeleteComment(c)

	assert.Equal(t, http.StatusInternalServerError, w.Code)
}
