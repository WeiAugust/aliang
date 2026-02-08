package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/WeiAugust/aliang/backend/internal/service"
)

// SearchHandler handles search requests
type SearchHandler struct {
	searchService *service.SearchService
}

// NewSearchHandler creates a new search handler
func NewSearchHandler(searchService *service.SearchService) *SearchHandler {
	return &SearchHandler{
		searchService: searchService,
	}
}

// SearchPosts searches posts by query
func (h *SearchHandler) SearchPosts(c *gin.Context) {
	query := c.Query("q")
	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "VALIDATION_ERROR",
				"message": "Query parameter 'q' is required",
			},
		})
		return
	}

	// Get pagination parameters
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	posts, err := h.searchService.SearchPosts(c.Request.Context(), query, offset, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "INTERNAL_ERROR",
				"message": "Failed to search posts",
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

// GetTrendingHashtags gets trending hashtags
func (h *SearchHandler) GetTrendingHashtags(c *gin.Context) {
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	hashtags, err := h.searchService.GetTrendingHashtags(c.Request.Context(), limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "INTERNAL_ERROR",
				"message": "Failed to get trending hashtags",
			},
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    hashtags,
	})
}

// GetPostsByHashtag gets posts by hashtag
func (h *SearchHandler) GetPostsByHashtag(c *gin.Context) {
	name := c.Param("name")
	if name == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "VALIDATION_ERROR",
				"message": "Hashtag name is required",
			},
		})
		return
	}

	// Get pagination parameters
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	posts, err := h.searchService.GetPostsByHashtag(c.Request.Context(), name, offset, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error": gin.H{
				"code":    "INTERNAL_ERROR",
				"message": "Failed to get posts by hashtag",
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
