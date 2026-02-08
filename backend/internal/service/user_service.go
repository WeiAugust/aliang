package service

import (
	"context"
	"fmt"

	"github.com/WeiAugust/aliang/backend/internal/model"
	"github.com/WeiAugust/aliang/backend/internal/repository"
)

// UserService handles user operations
type UserService struct {
	userRepo repository.UserRepository
}

// NewUserService creates a new user service
func NewUserService(userRepo repository.UserRepository) *UserService {
	return &UserService{
		userRepo: userRepo,
	}
}

// GetByID gets a user by ID
func (s *UserService) GetByID(ctx context.Context, id int64) (*model.User, error) {
	user, err := s.userRepo.GetByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("failed to get user: %w", err)
	}
	return user, nil
}

// Update updates a user profile
func (s *UserService) Update(ctx context.Context, user *model.User) error {
	if err := s.userRepo.Update(ctx, user); err != nil {
		return fmt.Errorf("failed to update user: %w", err)
	}
	return nil
}

// List lists users with pagination
func (s *UserService) List(ctx context.Context, offset, limit int) ([]*model.User, error) {
	users, err := s.userRepo.List(ctx, offset, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to list users: %w", err)
	}
	return users, nil
}

// Count counts total users
func (s *UserService) Count(ctx context.Context) (int64, error) {
	count, err := s.userRepo.Count(ctx)
	if err != nil {
		return 0, fmt.Errorf("failed to count users: %w", err)
	}
	return count, nil
}

// A5: GetDailyActiveUsers gets the count of users active in the last 24 hours
func (s *UserService) GetDailyActiveUsers(ctx context.Context) (int64, error) {
	count, err := s.userRepo.GetDailyActiveUsers(ctx)
	if err != nil {
		return 0, fmt.Errorf("failed to get daily active users: %w", err)
	}
	return count, nil
}
