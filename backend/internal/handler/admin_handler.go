package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/WeiAugust/aliang/backend/internal/service"
)

// AdminHandler handles admin requests
type AdminHandler struct {
	userService        *service.UserService
	postService        *service.PostService
	interactionService *service.InteractionService
}

// NewAdminHandler creates a new admin handler
func NewAdminHandler(
	userService *service.UserService,
	postService *service.PostService,
	interactionService *service.InteractionService,
) *AdminHandler {
	return &AdminHandler{
		userService:        userService,
		postService:        postService,
		interactionService: interactionService,
	}
}

// GetStats gets dashboard statistics
func (h *AdminHandler) GetStats(c *gin.Context) {
	ctx := c.Request.Context()

	// Get counts
	userCount, _ := h.userService.Count(ctx)
	postCount, _ := h.postService.Count(ctx)
	likeCount, _ := h.interactionService.CountTotalLikes(ctx)
	commentCount, _ := h.interactionService.CountTotalComments(ctx)

	// A5: Get real daily metrics
	dailyActiveUsers, _ := h.userService.GetDailyActiveUsers(ctx)
	dailyNewPosts, _ := h.postService.GetDailyNewPosts(ctx)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"total_users":        userCount,
			"total_posts":        postCount,
			"total_likes":        likeCount,
			"total_comments":     commentCount,
			"daily_active_users": dailyActiveUsers,
			"daily_new_posts":    dailyNewPosts,
		},
	})
}

// GetPosts gets all posts for admin (A3: use ListAllForAdmin to see all posts including self_only)
func (h *AdminHandler) GetPosts(c *gin.Context) {
	// Get pagination parameters
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	posts, err := h.postService.ListAllForAdmin(c.Request.Context(), offset, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "INTERNAL_ERROR",
				"message": "Failed to get posts",
			},
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"items":    posts,
			"has_more": len(posts) == limit,
		},
	})
}

// UpdatePostVisibilityRequest represents the update visibility request
type UpdatePostVisibilityRequest struct {
	Visibility string `json:"visibility" binding:"required,oneof=public self_only"`
}

// UpdatePostVisibility updates post visibility
func (h *AdminHandler) UpdatePostVisibility(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
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

	var req UpdatePostVisibilityRequest
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

	post, err := h.postService.GetByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "NOT_FOUND",
				"message": "Post not found",
			},
		})
		return
	}

	post.Visibility = req.Visibility
	if err := h.postService.Update(c.Request.Context(), post); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "INTERNAL_ERROR",
				"message": "Failed to update post visibility",
			},
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Post visibility updated",
	})
}

// UpdatePostLabelRequest represents the update label request
type UpdatePostLabelRequest struct {
	Label string `json:"label" binding:"required,oneof=normal recommended not_recommended"`
}

// UpdatePostLabel updates post label
func (h *AdminHandler) UpdatePostLabel(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
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

	var req UpdatePostLabelRequest
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

	post, err := h.postService.GetByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "NOT_FOUND",
				"message": "Post not found",
			},
		})
		return
	}

	post.Label = req.Label
	if err := h.postService.Update(c.Request.Context(), post); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "INTERNAL_ERROR",
				"message": "Failed to update post label",
			},
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Post label updated",
	})
}

// DeletePost deletes a post (admin)
func (h *AdminHandler) DeletePost(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
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

	if err := h.postService.Delete(c.Request.Context(), id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "INTERNAL_ERROR",
				"message": "Failed to delete post",
			},
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Post deleted successfully",
	})
}

// GetUsers gets all users for admin
func (h *AdminHandler) GetUsers(c *gin.Context) {
	// Get pagination parameters
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	users, err := h.userService.List(c.Request.Context(), offset, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "INTERNAL_ERROR",
				"message": "Failed to get users",
			},
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"items":    users,
			"has_more": len(users) == limit,
		},
	})
}

// GetUser gets a user by ID (admin)
func (h *AdminHandler) GetUser(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "VALIDATION_ERROR",
				"message": "Invalid user ID",
			},
		})
		return
	}

	user, err := h.userService.GetByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "NOT_FOUND",
				"message": "User not found",
			},
		})
		return
	}

	// Get user's posts
	posts, _ := h.postService.ListByUserID(c.Request.Context(), id, 0, 10)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"id":           user.ID,
			"phone":        user.Phone,
			"nickname":     user.Nickname,
			"avatar_url":   user.AvatarURL,
			"bio":          user.Bio,
			"status":       user.Status,
			"created_at":   user.CreatedAt,
			"recent_posts": posts,
		},
	})
}
