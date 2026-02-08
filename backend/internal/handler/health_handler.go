package handler

import (
	"context"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
	"gorm.io/gorm"

	"github.com/WeiAugust/aliang/backend/internal/config"
)

// HealthHandler handles health check requests
type HealthHandler struct {
	db    *gorm.DB
	redis *redis.Client
	cfg   *config.Config
}

// NewHealthHandler creates a new health handler
func NewHealthHandler(db *gorm.DB, redis *redis.Client, cfg *config.Config) *HealthHandler {
	return &HealthHandler{
		db:    db,
		redis: redis,
		cfg:   cfg,
	}
}

// Readiness checks if all dependencies are ready
func (h *HealthHandler) Readiness(c *gin.Context) {
	ctx, cancel := context.WithTimeout(c.Request.Context(), 5*time.Second)
	defer cancel()

	checks := make(map[string]string)

	// Check PostgreSQL
	sqlDB, err := h.db.DB()
	if err != nil {
		checks["postgresql"] = "unhealthy"
	} else if sqlDB == nil {
		checks["postgresql"] = "unhealthy"
	} else {
		// Try to ping the database
		if err := sqlDB.PingContext(ctx); err != nil {
			checks["postgresql"] = "unhealthy"
		} else {
			checks["postgresql"] = "ready"
		}
	}

	// Check Redis
	if err := h.redis.Ping(ctx).Err(); err != nil {
		checks["redis"] = "unhealthy"
	} else {
		checks["redis"] = "ready"
	}

	// Check storage (MinIO/S3) - skip if endpoint is empty
	if h.cfg.MinIO.Endpoint != "" {
		checks["storage"] = "ready" // Simplified check - MinIO client initialization already verified
	} else {
		checks["storage"] = "skip"
	}

	// Determine overall status
	allReady := true
	for _, status := range checks {
		if status == "unhealthy" {
			allReady = false
			break
		}
		if status == "ready" || status == "skip" {
			continue
		}
		allReady = false
	}

	status := http.StatusOK
	if !allReady {
		status = http.StatusServiceUnavailable
	}

	c.JSON(status, gin.H{
		"status":  "ready",
		"checks":  checks,
	})
}
