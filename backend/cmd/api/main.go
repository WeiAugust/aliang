package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
)

func main() {
	// Set Gin mode
	if os.Getenv("GIN_MODE") == "" {
		gin.SetMode(gin.ReleaseMode)
	}

	// Create router
	router := gin.Default()

	// Health check endpoint
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "healthy",
			"time":   time.Now().Unix(),
		})
	})

	// API v1 routes
	v1 := router.Group("/api/v1")
	{
		// Auth routes
		auth := v1.Group("/auth")
		{
			auth.POST("/sms/send", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"success": true,
					"data": gin.H{
						"code":       "123456",
						"expires_at": time.Now().Add(5 * time.Minute).Format(time.RFC3339),
					},
					"message": "Verification code sent",
				})
			})

			auth.POST("/sms/verify", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"success": true,
					"data": gin.H{
						"token": "mock-jwt-token",
						"user": gin.H{
							"id":         "1",
							"phone":      "13800138000",
							"nickname":   "User_1",
							"avatar":     "",
							"created_at": time.Now().Format(time.RFC3339),
						},
					},
				})
			})
		}

		// Admin auth routes
		admin := v1.Group("/admin")
		{
			adminAuth := admin.Group("/auth")
			{
				adminAuth.POST("/login", func(c *gin.Context) {
					c.JSON(http.StatusOK, gin.H{
						"success": true,
						"data": gin.H{
							"token": "mock-admin-jwt-token",
							"admin": gin.H{
								"id":       "1",
								"username": "admin",
								"role":     "admin",
							},
						},
					})
				})
			}

			// Admin stats
			admin.GET("/stats", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"success": true,
					"data": gin.H{
						"total_users":        1234,
						"total_posts":        5678,
						"total_likes":        12345,
						"total_comments":     6789,
						"daily_active_users": 456,
						"daily_new_posts":    123,
					},
				})
			})

			// Admin posts
			admin.GET("/posts", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"success": true,
					"data": gin.H{
						"items": []gin.H{
							{
								"id":         "1",
								"title":      "Sample Post 1",
								"author":     "User 1",
								"visibility": "public",
								"status":     "normal",
								"created_at": time.Now().Format(time.RFC3339),
							},
						},
						"next_cursor": nil,
						"has_more":    false,
					},
				})
			})

			// Admin users
			admin.GET("/users", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"success": true,
					"data": gin.H{
						"items": []gin.H{
							{
								"id":         "1",
								"phone":      "138****1234",
								"nickname":   "User_1",
								"post_count": 10,
								"status":     "active",
								"created_at": time.Now().Format(time.RFC3339),
							},
						},
						"next_cursor": nil,
						"has_more":    false,
					},
				})
			})
		}

		// Posts routes
		posts := v1.Group("/posts")
		{
			posts.GET("", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"success": true,
					"data": gin.H{
						"items": []gin.H{
							{
								"id":    "1",
								"title": "Sample Post",
								"user": gin.H{
									"id":       "1",
									"nickname": "User_1",
									"avatar":   "",
								},
								"content":       "This is a sample post",
								"media":         []gin.H{},
								"like_count":    0,
								"comment_count": 0,
								"is_liked":      false,
								"created_at":    time.Now().Format(time.RFC3339),
							},
						},
						"next_cursor": nil,
						"has_more":    false,
					},
				})
			})

			posts.GET("/:id", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"success": true,
					"data": gin.H{
						"id":    c.Param("id"),
						"title": "Sample Post",
						"user": gin.H{
							"id":       "1",
							"nickname": "User_1",
							"avatar":   "",
						},
						"content":       "This is a sample post",
						"media":         []gin.H{},
						"hashtags":      []string{},
						"like_count":    0,
						"comment_count": 0,
						"is_liked":      false,
						"created_at":    time.Now().Format(time.RFC3339),
					},
				})
			})
		}

		// Users routes
		users := v1.Group("/users")
		{
			users.GET("/me", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"success": true,
					"data": gin.H{
						"id":         "1",
						"phone":      "13800138000",
						"nickname":   "User_1",
						"avatar":     "",
						"bio":        "",
						"post_count": 0,
						"created_at": time.Now().Format(time.RFC3339),
					},
				})
			})
		}
	}

	// Get port from environment or use default
	port := os.Getenv("SERVER_PORT")
	if port == "" {
		port = "8080"
	}

	// Create HTTP server
	srv := &http.Server{
		Addr:    fmt.Sprintf(":%s", port),
		Handler: router,
	}

	// Start server in a goroutine
	go func() {
		log.Printf("Starting server on port %s", port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down server...")

	// Graceful shutdown with 5 second timeout
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	log.Println("Server exited")
}
