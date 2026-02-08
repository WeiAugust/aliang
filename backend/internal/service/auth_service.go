package service

import (
	"context"
	"fmt"

	"gorm.io/gorm"

	"github.com/WeiAugust/aliang/backend/internal/model"
	"github.com/WeiAugust/aliang/backend/internal/pkg"
	"github.com/WeiAugust/aliang/backend/internal/repository"
)

// AuthService handles authentication operations
type AuthService struct {
	userRepo   repository.UserRepository
	jwtManager *pkg.JWTManager
	smsService *pkg.SMSService
}

// NewAuthService creates a new auth service
func NewAuthService(
	userRepo repository.UserRepository,
	jwtManager *pkg.JWTManager,
	smsService *pkg.SMSService,
) *AuthService {
	return &AuthService{
		userRepo:   userRepo,
		jwtManager: jwtManager,
		smsService: smsService,
	}
}

// SendVerificationCode sends a verification code to the phone number
func (s *AuthService) SendVerificationCode(ctx context.Context, phone string) (string, error) {
	code, err := s.smsService.SendVerificationCode(ctx, phone)
	if err != nil {
		return "", fmt.Errorf("failed to send verification code: %w", err)
	}
	return code, nil
}

// VerifyAndLogin verifies the code and logs in or registers the user
func (s *AuthService) VerifyAndLogin(ctx context.Context, phone, code string) (string, *model.User, error) {
	// Verify code
	valid, err := s.smsService.VerifyCode(ctx, phone, code)
	if err != nil {
		return "", nil, fmt.Errorf("failed to verify code: %w", err)
	}
	if !valid {
		return "", nil, fmt.Errorf("invalid or expired verification code")
	}

	// Get or create user
	user, err := s.userRepo.GetByPhone(ctx, phone)
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			// Create new user
			user = &model.User{
				Phone:    phone,
				Nickname: fmt.Sprintf("User_%s", phone[len(phone)-4:]),
				Role:     "user",
				Status:   "active",
			}
			if err := s.userRepo.Create(ctx, user); err != nil {
				return "", nil, fmt.Errorf("failed to create user: %w", err)
			}
		} else {
			return "", nil, fmt.Errorf("failed to get user: %w", err)
		}
	}

	// Generate JWT token
	token, err := s.jwtManager.GenerateToken(user.ID, user.Phone, user.Role)
	if err != nil {
		return "", nil, fmt.Errorf("failed to generate token: %w", err)
	}

	return token, user, nil
}

// AdminLogin authenticates an admin user
func (s *AuthService) AdminLogin(ctx context.Context, username, password string) (string, *model.User, error) {
	// Get admin user by phone (using phone field for username)
	user, err := s.userRepo.GetByPhone(ctx, username)
	if err != nil {
		return "", nil, fmt.Errorf("invalid credentials")
	}

	// Check if user is admin
	if user.Role != "admin" {
		return "", nil, fmt.Errorf("invalid credentials")
	}

	// TODO: Implement proper password hashing and verification
	// For now, just check if user exists and is admin

	// Generate JWT token
	token, err := s.jwtManager.GenerateToken(user.ID, user.Phone, user.Role)
	if err != nil {
		return "", nil, fmt.Errorf("failed to generate token: %w", err)
	}

	return token, user, nil
}
