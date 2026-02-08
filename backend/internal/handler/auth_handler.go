package handler

import (
	"context"
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/WeiAugust/aliang/backend/internal/model"
)

type authServiceAPI interface {
	SendVerificationCode(ctx context.Context, phone string) (string, error)
	VerifyAndLogin(ctx context.Context, phone, code string) (string, *model.User, error)
	AdminLogin(ctx context.Context, username, password string) (string, *model.User, error)
}

// AuthHandler handles authentication requests
type AuthHandler struct {
	authService authServiceAPI
}

// NewAuthHandler creates a new auth handler
func NewAuthHandler(authService authServiceAPI) *AuthHandler {
	return &AuthHandler{
		authService: authService,
	}
}

// SendCodeRequest represents the send code request
type SendCodeRequest struct {
	Phone string `json:"phone" binding:"required"`
}

// SendCode sends a verification code
func (h *AuthHandler) SendCode(c *gin.Context) {
	var req SendCodeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "VALIDATION_ERROR",
				"message": err.Error(),
			},
		})
		return
	}

	code, err := h.authService.SendVerificationCode(c.Request.Context(), req.Phone)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "INTERNAL_ERROR",
				"message": "Failed to send verification code",
			},
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"code":       code, // Only in development
			"expires_at": "5 minutes",
		},
		"message": "Verification code sent",
	})
}

// VerifyCodeRequest represents the verify code request
type VerifyCodeRequest struct {
	Phone string `json:"phone" binding:"required"`
	Code  string `json:"code" binding:"required"`
}

// VerifyCode verifies the code and logs in
func (h *AuthHandler) VerifyCode(c *gin.Context) {
	var req VerifyCodeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "VALIDATION_ERROR",
				"message": err.Error(),
			},
		})
		return
	}

	token, user, err := h.authService.VerifyAndLogin(c.Request.Context(), req.Phone, req.Code)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "UNAUTHORIZED",
				"message": err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"token": token,
			"user": gin.H{
				"id":         user.ID,
				"phone":      user.Phone,
				"nickname":   user.Nickname,
				"avatar_url": user.AvatarURL,
				"created_at": user.CreatedAt,
			},
		},
	})
}

// AdminLoginRequest represents the admin login request
type AdminLoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// AdminLogin handles admin login
func (h *AuthHandler) AdminLogin(c *gin.Context) {
	var req AdminLoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "VALIDATION_ERROR",
				"message": err.Error(),
			},
		})
		return
	}

	token, user, err := h.authService.AdminLogin(c.Request.Context(), req.Username, req.Password)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "UNAUTHORIZED",
				"message": "Invalid credentials",
			},
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"token": token,
			"admin": gin.H{
				"id":       user.ID,
				"username": user.Phone,
				"role":     user.Role,
			},
		},
	})
}
