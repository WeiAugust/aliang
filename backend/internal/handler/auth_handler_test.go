package handler

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/WeiAugust/aliang/backend/internal/model"
)

type mockAuthService struct {
	sendCodeFunc   func(ctx context.Context, phone string) (string, error)
	verifyCodeFunc func(ctx context.Context, phone, code string) (string, *model.User, error)
	adminLoginFunc func(ctx context.Context, username, password string) (string, *model.User, error)
}

func (m *mockAuthService) SendVerificationCode(ctx context.Context, phone string) (string, error) {
	if m.sendCodeFunc == nil {
		return "123456", nil
	}
	return m.sendCodeFunc(ctx, phone)
}

func (m *mockAuthService) VerifyAndLogin(ctx context.Context, phone, code string) (string, *model.User, error) {
	if m.verifyCodeFunc == nil {
		return "token", &model.User{ID: 1, Phone: phone, Nickname: "u"}, nil
	}
	return m.verifyCodeFunc(ctx, phone, code)
}

func (m *mockAuthService) AdminLogin(ctx context.Context, username, password string) (string, *model.User, error) {
	if m.adminLoginFunc == nil {
		return "admin-token", &model.User{ID: 1, Phone: username, Role: "admin"}, nil
	}
	return m.adminLoginFunc(ctx, username, password)
}

func makeJSONRequest(t *testing.T, method, path string, payload any) *http.Request {
	t.Helper()
	body, err := json.Marshal(payload)
	require.NoError(t, err)
	req := httptest.NewRequest(method, path, bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	return req
}

func TestAuthHandler_SendCode(t *testing.T) {
	gin.SetMode(gin.TestMode)

	h := NewAuthHandler(&mockAuthService{
		sendCodeFunc: func(_ context.Context, phone string) (string, error) {
			assert.Equal(t, "13800000000", phone)
			return "111222", nil
		},
	})

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = makeJSONRequest(t, http.MethodPost, "/auth/sms/send", gin.H{"phone": "13800000000"})

	h.SendCode(c)

	assert.Equal(t, http.StatusOK, w.Code)
	assert.Contains(t, w.Body.String(), `"code":"111222"`)
}

func TestAuthHandler_VerifyCode(t *testing.T) {
	gin.SetMode(gin.TestMode)

	h := NewAuthHandler(&mockAuthService{
		verifyCodeFunc: func(_ context.Context, phone, code string) (string, *model.User, error) {
			assert.Equal(t, "13800000000", phone)
			assert.Equal(t, "123456", code)
			return "jwt", &model.User{ID: 1, Phone: phone, Nickname: "u", CreatedAt: time.Now()}, nil
		},
	})

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = makeJSONRequest(t, http.MethodPost, "/auth/sms/verify", gin.H{"phone": "13800000000", "code": "123456"})

	h.VerifyCode(c)

	assert.Equal(t, http.StatusOK, w.Code)
	assert.Contains(t, w.Body.String(), `"token":"jwt"`)
	assert.Contains(t, w.Body.String(), `"phone":"13800000000"`)
}

func TestAuthHandler_AdminLoginUnauthorized(t *testing.T) {
	gin.SetMode(gin.TestMode)

	h := NewAuthHandler(&mockAuthService{
		adminLoginFunc: func(_ context.Context, _, _ string) (string, *model.User, error) {
			return "", nil, errors.New("invalid")
		},
	})

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = makeJSONRequest(t, http.MethodPost, "/admin/auth/login", gin.H{"username": "a", "password": "b"})

	h.AdminLogin(c)

	assert.Equal(t, http.StatusUnauthorized, w.Code)
	assert.Contains(t, w.Body.String(), "Invalid credentials")
}
