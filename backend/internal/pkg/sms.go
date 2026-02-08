package pkg

import (
	"context"
	"fmt"
	"math/rand"
	"time"

	"github.com/redis/go-redis/v9"
)

// SMSService handles SMS operations
type SMSService struct {
	redis       *redis.Client
	mockEnabled bool
	mockCode    string
}

// NewSMSService creates a new SMS service
func NewSMSService(redis *redis.Client, mockEnabled bool, mockCode string) *SMSService {
	return &SMSService{
		redis:       redis,
		mockEnabled: mockEnabled,
		mockCode:    mockCode,
	}
}

// SendVerificationCode sends a verification code to the phone number
func (s *SMSService) SendVerificationCode(ctx context.Context, phone string) (string, error) {
	var code string

	if s.mockEnabled {
		// Use mock code in development
		code = s.mockCode
	} else {
		// Generate random 6-digit code
		code = fmt.Sprintf("%06d", rand.Intn(1000000))
		// TODO: Integrate with real SMS provider (Twilio, AWS SNS, etc.)
	}

	// Store code in Redis with 5-minute expiry
	key := fmt.Sprintf("sms:code:%s", phone)
	err := s.redis.Set(ctx, key, code, 5*time.Minute).Err()
	if err != nil {
		return "", fmt.Errorf("failed to store verification code: %w", err)
	}

	return code, nil
}

// VerifyCode verifies the verification code for the phone number
func (s *SMSService) VerifyCode(ctx context.Context, phone, code string) (bool, error) {
	key := fmt.Sprintf("sms:code:%s", phone)

	// Get stored code from Redis
	storedCode, err := s.redis.Get(ctx, key).Result()
	if err == redis.Nil {
		return false, nil // Code not found or expired
	}
	if err != nil {
		return false, fmt.Errorf("failed to get verification code: %w", err)
	}

	// Compare codes
	if storedCode != code {
		return false, nil
	}

	// Delete code after successful verification
	s.redis.Del(ctx, key)

	return true, nil
}
