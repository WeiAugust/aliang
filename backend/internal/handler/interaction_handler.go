package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/WeiAugust/aliang/backend/internal/middleware"
	"github.com/WeiAugust/aliang/backend/internal/model"
	"github.com/WeiAugust/aliang/backend/internal/service"
)

// InteractionHandler handles like and comment requests
type InteractionHandler struct {
	interactionService *service.InteractionService
}

// NewInteractionHandler creates a new interaction handler
func NewInteractionHandler(interactionService *service.InteractionService) *InteractionHandler {
	return &InteractionHandler{
		interactionService: interactionService,
	}
}

// ToggleLike toggles a like on a post
func (h *InteractionHandler) ToggleLike(c *gin.Context) {
	userID, ok := middleware.GetUserID(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "UNAUTHORIZED",
				"message": "User not authenticated",
			},
		})
		return
	}

	idStr := c.Param("id")
	postID, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "VALIDATION_ERROR",
				"message": "Invalid post ID",
			},
		})
		return
	}

	isLiked, err := h.interactionService.ToggleLike(c.Request.Context(), userID, postID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "INTERNAL_ERROR",
				"message": "Failed to toggle like",
			},
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"is_liked": isLiked,
		},
	})
}

// GetComments gets comments for a post
func (h *InteractionHandler) GetComments(c *gin.Context) {
	idStr := c.Param("id")
	postID, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "VALIDATION_ERROR",
				"message": "Invalid post ID",
			},
		})
		return
	}

	// Get pagination parameters
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	comments, err := h.interactionService.ListComments(c.Request.Context(), postID, offset, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "INTERNAL_ERROR",
				"message": "Failed to get comments",
			},
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"items":    comments,
			"has_more": len(comments) == limit,
		},
	})
}

// CreateCommentRequest represents the create comment request
type CreateCommentRequest struct {
	Content string `json:"content" binding:"required"`
}

// CreateComment creates a new comment
func (h *InteractionHandler) CreateComment(c *gin.Context) {
	userID, ok := middleware.GetUserID(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "UNAUTHORIZED",
				"message": "User not authenticated",
			},
		})
		return
	}

	idStr := c.Param("id")
	postID, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "VALIDATION_ERROR",
				"message": "Invalid post ID",
			},
		})
		return
	}

	var req CreateCommentRequest
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

	comment := &model.Comment{
		UserID:  userID,
		PostID:  postID,
		Content: req.Content,
	}

	if err := h.interactionService.CreateComment(c.Request.Context(), comment); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "INTERNAL_ERROR",
				"message": "Failed to create comment",
			},
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data": gin.H{
			"id":         comment.ID,
			"user_id":    comment.UserID,
			"post_id":    comment.PostID,
			"content":    comment.Content,
			"created_at": comment.CreatedAt,
		},
	})
}

// DeleteComment deletes a comment
func (h *InteractionHandler) DeleteComment(c *gin.Context) {
	_, ok := middleware.GetUserID(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "UNAUTHORIZED",
				"message": "User not authenticated",
			},
		})
		return
	}

	idStr := c.Param("id")
	commentID, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "VALIDATION_ERROR",
				"message": "Invalid comment ID",
			},
		})
		return
	}

	// TODO: Check if user owns the comment before deleting

	if err := h.interactionService.DeleteComment(c.Request.Context(), commentID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "INTERNAL_ERROR",
				"message": "Failed to delete comment",
			},
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Comment deleted successfully",
	})
}
