package handler

import (
	"context"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/WeiAugust/aliang/backend/internal/middleware"
	"github.com/WeiAugust/aliang/backend/internal/model"
)

type postServiceAPI interface {
	Create(ctx context.Context, post *model.Post, mediaURLs []string) error
	List(ctx context.Context, offset, limit int) ([]*model.Post, error)
	GetByID(ctx context.Context, id int64) (*model.Post, error)
	GetByIDWithVisibility(ctx context.Context, id int64, userID int64, isAdmin bool) (*model.Post, error)
	Delete(ctx context.Context, id int64) error
}

// PostHandler handles post requests
type PostHandler struct {
	postService postServiceAPI
}

// NewPostHandler creates a new post handler
func NewPostHandler(postService postServiceAPI) *PostHandler {
	return &PostHandler{
		postService: postService,
	}
}

// CreatePostRequest represents the create post request
type CreatePostRequest struct {
	Title     string   `json:"title" binding:"required"`
	Content   string   `json:"content" binding:"required"`
	PostType  string   `json:"post_type" binding:"required,oneof=image video"`
	MediaURLs []string `json:"media_urls"` // A1: Changed from media_ids to media_urls
}

// CreatePost creates a new post
func (h *PostHandler) CreatePost(c *gin.Context) {
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

	var req CreatePostRequest
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

	post := &model.Post{
		UserID:     userID,
		Title:      req.Title,
		Content:    req.Content,
		PostType:   req.PostType,
		Visibility: "public", // Default visibility
	}

	// A1: Pass mediaURLs to service
	if err := h.postService.Create(c.Request.Context(), post, req.MediaURLs); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "VALIDATION_ERROR",
				"message": err.Error(),
			},
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data": gin.H{
			"id":            post.ID,
			"user_id":       post.UserID,
			"title":         post.Title,
			"content":       post.Content,
			"post_type":     post.PostType,
			"visibility":    post.Visibility,
			"like_count":    post.LikeCount,
			"comment_count": post.CommentCount,
			"created_at":    post.CreatedAt,
		},
	})
}

// GetPosts gets a list of posts
func (h *PostHandler) GetPosts(c *gin.Context) {
	// Get pagination parameters
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	posts, err := h.postService.List(c.Request.Context(), offset, limit)
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

// GetPost gets a post by ID
func (h *PostHandler) GetPost(c *gin.Context) {
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

	// A3: Get user info for visibility check
	userID, _ := middleware.GetUserID(c)
	isAdmin := middleware.IsAdmin(c)

	post, err := h.postService.GetByIDWithVisibility(c.Request.Context(), id, userID, isAdmin)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "NOT_FOUND",
				"message": "Post not found or access denied",
			},
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    post,
	})
}

// DeletePost deletes a post
func (h *PostHandler) DeletePost(c *gin.Context) {
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

	// Get post to check ownership
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

	// Check if user owns the post
	if post.UserID != userID {
		c.JSON(http.StatusForbidden, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "FORBIDDEN",
				"message": "You can only delete your own posts",
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
