package service

import (
	"context"
	"errors"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gorm.io/gorm"

	"github.com/WeiAugust/aliang/backend/internal/model"
)

type mockAuthUserRepo struct {
	getByPhoneFunc func(ctx context.Context, phone string) (*model.User, error)
	createFunc     func(ctx context.Context, user *model.User) error
}

func (m *mockAuthUserRepo) Create(ctx context.Context, user *model.User) error {
	if m.createFunc == nil {
		return nil
	}
	return m.createFunc(ctx, user)
}

func (m *mockAuthUserRepo) GetByID(_ context.Context, _ int64) (*model.User, error) {
	return nil, errors.New("not implemented")
}

func (m *mockAuthUserRepo) GetByPhone(ctx context.Context, phone string) (*model.User, error) {
	if m.getByPhoneFunc == nil {
		return nil, gorm.ErrRecordNotFound
	}
	return m.getByPhoneFunc(ctx, phone)
}

func (m *mockAuthUserRepo) Update(_ context.Context, _ *model.User) error {
	return errors.New("not implemented")
}

func (m *mockAuthUserRepo) Delete(_ context.Context, _ int64) error {
	return errors.New("not implemented")
}

func (m *mockAuthUserRepo) List(_ context.Context, _, _ int) ([]*model.User, error) {
	return nil, errors.New("not implemented")
}

func (m *mockAuthUserRepo) Count(_ context.Context) (int64, error) {
	return 0, errors.New("not implemented")
}

func (m *mockAuthUserRepo) GetStatsByUserID(_ context.Context, _ int64) (postCount, likeCount, commentCount int64, err error) {
	return 0, 0, 0, nil
}

// A5: GetDailyActiveUsers mock
func (m *mockAuthUserRepo) GetDailyActiveUsers(_ context.Context) (int64, error) {
	return 0, nil
}

type mockTokenManager struct {
	generateTokenFunc func(userID int64, phone, role string) (string, error)
}

func (m *mockTokenManager) GenerateToken(userID int64, phone, role string) (string, error) {
	if m.generateTokenFunc == nil {
		return "token", nil
	}
	return m.generateTokenFunc(userID, phone, role)
}

type mockSMSProvider struct {
	sendFunc   func(ctx context.Context, phone string) (string, error)
	verifyFunc func(ctx context.Context, phone, code string) (bool, error)
}

func (m *mockSMSProvider) SendVerificationCode(ctx context.Context, phone string) (string, error) {
	if m.sendFunc == nil {
		return "123456", nil
	}
	return m.sendFunc(ctx, phone)
}

func (m *mockSMSProvider) VerifyCode(ctx context.Context, phone, code string) (bool, error) {
	if m.verifyFunc == nil {
		return true, nil
	}
	return m.verifyFunc(ctx, phone, code)
}

func TestAuthService_SendVerificationCode(t *testing.T) {
	svc := NewAuthService(
		&mockAuthUserRepo{},
		&mockTokenManager{},
		&mockSMSProvider{
			sendFunc: func(_ context.Context, phone string) (string, error) {
				assert.Equal(t, "13800000000", phone)
				return "654321", nil
			},
		},
	)

	code, err := svc.SendVerificationCode(context.Background(), "13800000000")
	require.NoError(t, err)
	assert.Equal(t, "654321", code)
}

func TestAuthService_SendVerificationCodeError(t *testing.T) {
	svc := NewAuthService(
		&mockAuthUserRepo{},
		&mockTokenManager{},
		&mockSMSProvider{
			sendFunc: func(_ context.Context, _ string) (string, error) {
				return "", errors.New("sms down")
			},
		},
	)

	_, err := svc.SendVerificationCode(context.Background(), "13800000000")
	require.Error(t, err)
	assert.Contains(t, err.Error(), "failed to send verification code")
	assert.Contains(t, err.Error(), "sms down")
}

func TestAuthService_VerifyAndLoginExistingUser(t *testing.T) {
	user := &model.User{ID: 1, Phone: "13800000000", Role: "user", Nickname: "n"}
	svc := NewAuthService(
		&mockAuthUserRepo{
			getByPhoneFunc: func(_ context.Context, phone string) (*model.User, error) {
				assert.Equal(t, "13800000000", phone)
				return user, nil
			},
		},
		&mockTokenManager{
			generateTokenFunc: func(userID int64, phone, role string) (string, error) {
				assert.Equal(t, int64(1), userID)
				assert.Equal(t, "13800000000", phone)
				assert.Equal(t, "user", role)
				return "jwt-token", nil
			},
		},
		&mockSMSProvider{
			verifyFunc: func(_ context.Context, phone, code string) (bool, error) {
				assert.Equal(t, "13800000000", phone)
				assert.Equal(t, "123456", code)
				return true, nil
			},
		},
	)

	token, gotUser, err := svc.VerifyAndLogin(context.Background(), "13800000000", "123456")
	require.NoError(t, err)
	assert.Equal(t, "jwt-token", token)
	assert.Equal(t, user, gotUser)
}

func TestAuthService_VerifyAndLoginCreateNewUser(t *testing.T) {
	var createdUser *model.User
	svc := NewAuthService(
		&mockAuthUserRepo{
			getByPhoneFunc: func(_ context.Context, _ string) (*model.User, error) {
				return nil, gorm.ErrRecordNotFound
			},
			createFunc: func(_ context.Context, user *model.User) error {
				createdUser = user
				user.ID = 99
				return nil
			},
		},
		&mockTokenManager{
			generateTokenFunc: func(userID int64, phone, role string) (string, error) {
				assert.Equal(t, int64(99), userID)
				assert.Equal(t, "123", phone)
				assert.Equal(t, "user", role)
				return "new-token", nil
			},
		},
		&mockSMSProvider{
			verifyFunc: func(_ context.Context, _ string, _ string) (bool, error) {
				return true, nil
			},
		},
	)

	token, user, err := svc.VerifyAndLogin(context.Background(), "123", "123456")
	require.NoError(t, err)
	assert.Equal(t, "new-token", token)
	require.NotNil(t, createdUser)
	assert.Equal(t, "User_123", createdUser.Nickname)
	assert.Equal(t, "active", createdUser.Status)
	assert.Equal(t, int64(99), user.ID)
}

func TestAuthService_VerifyAndLoginInvalidCode(t *testing.T) {
	svc := NewAuthService(
		&mockAuthUserRepo{},
		&mockTokenManager{},
		&mockSMSProvider{
			verifyFunc: func(_ context.Context, _, _ string) (bool, error) {
				return false, nil
			},
		},
	)

	_, _, err := svc.VerifyAndLogin(context.Background(), "13800000000", "000000")
	require.Error(t, err)
	assert.Contains(t, err.Error(), "invalid or expired verification code")
}

func TestAuthService_AdminLogin(t *testing.T) {
	// Password "pwd" bcrypt hash (generated with htpasswd -nbBC 10 "" pwd)
	admin := &model.User{ID: 7, Phone: "admin", Role: "admin", PasswordHash: "$2y$10$7yLVxiPlnQZYJhwcQHhBmOSaFqk2/wSSw/7wLwZUR8EFFFm8PkeuW"}
	svc := NewAuthService(
		&mockAuthUserRepo{
			getByPhoneFunc: func(_ context.Context, phone string) (*model.User, error) {
				assert.Equal(t, "admin", phone)
				return admin, nil
			},
		},
		&mockTokenManager{
			generateTokenFunc: func(userID int64, phone, role string) (string, error) {
				assert.Equal(t, int64(7), userID)
				assert.Equal(t, "admin", phone)
				assert.Equal(t, "admin", role)
				return "admin-token", nil
			},
		},
		&mockSMSProvider{},
	)

	token, user, err := svc.AdminLogin(context.Background(), "admin", "pwd")
	require.NoError(t, err)
	assert.Equal(t, "admin-token", token)
	assert.Equal(t, admin, user)
}

func TestAuthService_AdminLoginNonAdmin(t *testing.T) {
	svc := NewAuthService(
		&mockAuthUserRepo{
			getByPhoneFunc: func(_ context.Context, _ string) (*model.User, error) {
				return &model.User{ID: 8, Phone: "user", Role: "user"}, nil
			},
		},
		&mockTokenManager{},
		&mockSMSProvider{},
	)

	_, _, err := svc.AdminLogin(context.Background(), "user", "pwd")
	require.Error(t, err)
	assert.Contains(t, err.Error(), "invalid credentials")
}
