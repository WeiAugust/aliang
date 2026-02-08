package handler

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"

	"github.com/WeiAugust/aliang/backend/internal/service"
)

// UploadHandler handles file upload operations
type UploadHandler struct {
	storageService *service.StorageService
	logger         *zap.Logger
}

// NewUploadHandler creates a new upload handler
func NewUploadHandler(storageService *service.StorageService, logger *zap.Logger) *UploadHandler {
	return &UploadHandler{
		storageService: storageService,
		logger:         logger,
	}
}

// UploadImage handles image upload
func (h *UploadHandler) UploadImage(c *gin.Context) {
	// Get file from form
	file, err := c.FormFile("file")
	if err != nil {
		h.logger.Error("Failed to get file from form", zap.Error(err))
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "VALIDATION_ERROR",
				"message": "No file uploaded",
			},
		})
		return
	}

	// Validate file type
	if !isImageFile(file.Filename) {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "VALIDATION_ERROR",
				"message": "Invalid file type. Only images are allowed (jpg, jpeg, png, gif, webp)",
			},
		})
		return
	}

	// Validate file size (max 10MB)
	if file.Size > 10*1024*1024 {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "VALIDATION_ERROR",
				"message": "File size exceeds 10MB limit",
			},
		})
		return
	}

	// Open file
	src, err := file.Open()
	if err != nil {
		h.logger.Error("Failed to open file", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "INTERNAL_ERROR",
				"message": "Failed to open file",
			},
		})
		return
	}
	defer src.Close()

	// Upload to storage
	url, err := h.storageService.UploadImage(c.Request.Context(), file.Filename, src, file.Size)
	if err != nil {
		h.logger.Error("Failed to upload image", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "INTERNAL_ERROR",
				"message": "Failed to upload file",
			},
		})
		return
	}

	h.logger.Info("Image uploaded successfully",
		zap.String("filename", file.Filename),
		zap.String("url", url),
	)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"url":           url,
			"thumbnail_url": url, // TODO: Generate thumbnail
		},
	})
}

// UploadVideo handles video upload
func (h *UploadHandler) UploadVideo(c *gin.Context) {
	// Get file from form
	file, err := c.FormFile("file")
	if err != nil {
		h.logger.Error("Failed to get file from form", zap.Error(err))
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "VALIDATION_ERROR",
				"message": "No file uploaded",
			},
		})
		return
	}

	// Validate file type
	if !isVideoFile(file.Filename) {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "VALIDATION_ERROR",
				"message": "Invalid file type. Only videos are allowed (mp4, mov, avi, webm)",
			},
		})
		return
	}

	// Validate file size (max 100MB)
	if file.Size > 100*1024*1024 {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "VALIDATION_ERROR",
				"message": "File size exceeds 100MB limit",
			},
		})
		return
	}

	// Open file
	src, err := file.Open()
	if err != nil {
		h.logger.Error("Failed to open file", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "INTERNAL_ERROR",
				"message": "Failed to open file",
			},
		})
		return
	}
	defer src.Close()

	// Upload to storage
	url, err := h.storageService.UploadVideo(c.Request.Context(), file.Filename, src, file.Size)
	if err != nil {
		h.logger.Error("Failed to upload video", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "INTERNAL_ERROR",
				"message": "Failed to upload file",
			},
		})
		return
	}

	h.logger.Info("Video uploaded successfully",
		zap.String("filename", file.Filename),
		zap.String("url", url),
	)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"url":           url,
			"thumbnail_url": "", // TODO: Generate video thumbnail
		},
	})
}

// isImageFile checks if the file is an image
func isImageFile(filename string) bool {
	ext := strings.ToLower(filename[strings.LastIndex(filename, "."):])
	return ext == ".jpg" || ext == ".jpeg" || ext == ".png" || ext == ".gif" || ext == ".webp"
}

// isVideoFile checks if the file is a video
func isVideoFile(filename string) bool {
	ext := strings.ToLower(filename[strings.LastIndex(filename, "."):])
	return ext == ".mp4" || ext == ".mov" || ext == ".avi" || ext == ".webm"
}
