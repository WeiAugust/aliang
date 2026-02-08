package service

import (
	"context"
	"errors"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/WeiAugust/aliang/backend/internal/model"
)

type mockLikeRepo struct {
	existsFunc func(ctx context.Context, userID, postID int64) (bool, error)
	createFunc func(ctx context.Context, like *model.Like) error
	deleteFunc func(ctx context.Context, userID, postID int64) error
	countFunc  func(ctx context.Context) (int64, error)
}

func (m *mockLikeRepo) Create(ctx context.Context, like *model.Like) error {
	if m.createFunc == nil {
		return nil
	}
	return m.createFunc(ctx, like)
}

func (m *mockLikeRepo) Delete(ctx context.Context, userID, postID int64) error {
	if m.deleteFunc == nil {
		return nil
	}
	return m.deleteFunc(ctx, userID, postID)
}

func (m *mockLikeRepo) Exists(ctx context.Context, userID, postID int64) (bool, error) {
	if m.existsFunc == nil {
		return false, nil
	}
	return m.existsFunc(ctx, userID, postID)
}

func (m *mockLikeRepo) CountByPostID(_ context.Context, _ int64) (int64, error) {
	return 0, errors.New("not implemented")
}

func (m *mockLikeRepo) Count(ctx context.Context) (int64, error) {
	if m.countFunc == nil {
		return 0, nil
	}
	return m.countFunc(ctx)
}

type mockCommentRepo struct {
	createFunc        func(ctx context.Context, comment *model.Comment) error
	getByIDFunc       func(ctx context.Context, id int64) (*model.Comment, error)
	deleteFunc        func(ctx context.Context, id int64) error
	listByPostIDFunc  func(ctx context.Context, postID int64, offset, limit int) ([]*model.Comment, error)
	countFunc         func(ctx context.Context) (int64, error)
	countByPostIDFunc func(ctx context.Context, postID int64) (int64, error)
}

func (m *mockCommentRepo) Create(ctx context.Context, comment *model.Comment) error {
	if m.createFunc == nil {
		return nil
	}
	return m.createFunc(ctx, comment)
}

func (m *mockCommentRepo) GetByID(ctx context.Context, id int64) (*model.Comment, error) {
	if m.getByIDFunc == nil {
		return &model.Comment{ID: id, PostID: 1}, nil
	}
	return m.getByIDFunc(ctx, id)
}

func (m *mockCommentRepo) Delete(ctx context.Context, id int64) error {
	if m.deleteFunc == nil {
		return nil
	}
	return m.deleteFunc(ctx, id)
}

func (m *mockCommentRepo) ListByPostID(ctx context.Context, postID int64, offset, limit int) ([]*model.Comment, error) {
	if m.listByPostIDFunc == nil {
		return []*model.Comment{}, nil
	}
	return m.listByPostIDFunc(ctx, postID, offset, limit)
}

func (m *mockCommentRepo) Count(ctx context.Context) (int64, error) {
	if m.countFunc == nil {
		return 0, nil
	}
	return m.countFunc(ctx)
}

func (m *mockCommentRepo) CountByPostID(ctx context.Context, postID int64) (int64, error) {
	if m.countByPostIDFunc == nil {
		return 0, nil
	}
	return m.countByPostIDFunc(ctx, postID)
}

type mockInteractionPostRepo struct {
	incLikeFunc    func(ctx context.Context, postID int64) error
	decLikeFunc    func(ctx context.Context, postID int64) error
	incCommentFunc func(ctx context.Context, postID int64) error
	decCommentFunc func(ctx context.Context, postID int64) error
}

func (m *mockInteractionPostRepo) IncrementLikeCount(ctx context.Context, postID int64) error {
	if m.incLikeFunc == nil {
		return nil
	}
	return m.incLikeFunc(ctx, postID)
}

func (m *mockInteractionPostRepo) DecrementLikeCount(ctx context.Context, postID int64) error {
	if m.decLikeFunc == nil {
		return nil
	}
	return m.decLikeFunc(ctx, postID)
}

func (m *mockInteractionPostRepo) IncrementCommentCount(ctx context.Context, postID int64) error {
	if m.incCommentFunc == nil {
		return nil
	}
	return m.incCommentFunc(ctx, postID)
}

func (m *mockInteractionPostRepo) DecrementCommentCount(ctx context.Context, postID int64) error {
	if m.decCommentFunc == nil {
		return nil
	}
	return m.decCommentFunc(ctx, postID)
}

func TestInteractionService_ToggleLikeCreate(t *testing.T) {
	svc := NewInteractionService(
		&mockLikeRepo{
			existsFunc: func(_ context.Context, userID, postID int64) (bool, error) {
				assert.Equal(t, int64(1), userID)
				assert.Equal(t, int64(2), postID)
				return false, nil
			},
			createFunc: func(_ context.Context, like *model.Like) error {
				assert.Equal(t, int64(1), like.UserID)
				assert.Equal(t, int64(2), like.PostID)
				return nil
			},
		},
		&mockCommentRepo{},
		&mockInteractionPostRepo{},
	)

	isLiked, err := svc.ToggleLike(context.Background(), 1, 2)
	require.NoError(t, err)
	assert.True(t, isLiked)
}

func TestInteractionService_ToggleLikeDelete(t *testing.T) {
	svc := NewInteractionService(
		&mockLikeRepo{
			existsFunc: func(_ context.Context, _, _ int64) (bool, error) { return true, nil },
			deleteFunc: func(_ context.Context, userID, postID int64) error {
				assert.Equal(t, int64(1), userID)
				assert.Equal(t, int64(2), postID)
				return nil
			},
		},
		&mockCommentRepo{},
		&mockInteractionPostRepo{},
	)

	isLiked, err := svc.ToggleLike(context.Background(), 1, 2)
	require.NoError(t, err)
	assert.False(t, isLiked)
}

func TestInteractionService_CreateAndDeleteComment(t *testing.T) {
	svc := NewInteractionService(
		&mockLikeRepo{},
		&mockCommentRepo{
			createFunc: func(_ context.Context, c *model.Comment) error {
				assert.Equal(t, int64(10), c.PostID)
				return nil
			},
			getByIDFunc: func(_ context.Context, id int64) (*model.Comment, error) {
				assert.Equal(t, int64(9), id)
				return &model.Comment{ID: 9, PostID: 10}, nil
			},
			deleteFunc: func(_ context.Context, id int64) error {
				assert.Equal(t, int64(9), id)
				return nil
			},
		},
		&mockInteractionPostRepo{},
	)

	err := svc.CreateComment(context.Background(), &model.Comment{PostID: 10, Content: "hi"})
	require.NoError(t, err)

	err = svc.DeleteComment(context.Background(), 9)
	require.NoError(t, err)
}

func TestInteractionService_CountMethods(t *testing.T) {
	svc := NewInteractionService(
		&mockLikeRepo{
			countFunc: func(_ context.Context) (int64, error) { return 12, nil },
		},
		&mockCommentRepo{
			countFunc: func(_ context.Context) (int64, error) { return 33, nil },
			countByPostIDFunc: func(_ context.Context, postID int64) (int64, error) {
				assert.Equal(t, int64(1), postID)
				return 5, nil
			},
		},
		&mockInteractionPostRepo{},
	)

	commentCount, err := svc.CountComments(context.Background(), 1)
	require.NoError(t, err)
	assert.Equal(t, int64(5), commentCount)

	likeCount, err := svc.CountTotalLikes(context.Background())
	require.NoError(t, err)
	assert.Equal(t, int64(12), likeCount)

	totalComments, err := svc.CountTotalComments(context.Background())
	require.NoError(t, err)
	assert.Equal(t, int64(33), totalComments)
}
