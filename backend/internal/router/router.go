package router

import (
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"

	"github.com/WeiAugust/aliang/backend/internal/config"
	"github.com/WeiAugust/aliang/backend/internal/handler"
	"github.com/WeiAugust/aliang/backend/internal/middleware"
	"github.com/WeiAugust/aliang/backend/internal/pkg"
)

// Router holds all handlers and dependencies
type Router struct {
	authHandler        *handler.AuthHandler
	userHandler        *handler.UserHandler
	postHandler        *handler.PostHandler
	interactionHandler *handler.InteractionHandler
	searchHandler      *handler.SearchHandler
	adminHandler       *handler.AdminHandler
	uploadHandler      *handler.UploadHandler
	healthHandler      *handler.HealthHandler
	jwtManager         *pkg.JWTManager
	logger             *zap.Logger
	config             *config.Config
}

// NewRouter creates a new router
func NewRouter(
	authHandler *handler.AuthHandler,
	userHandler *handler.UserHandler,
	postHandler *handler.PostHandler,
	interactionHandler *handler.InteractionHandler,
	searchHandler *handler.SearchHandler,
	adminHandler *handler.AdminHandler,
	uploadHandler *handler.UploadHandler,
	healthHandler *handler.HealthHandler,
	jwtManager *pkg.JWTManager,
	logger *zap.Logger,
	cfg *config.Config,
) *Router {
	return &Router{
		authHandler:        authHandler,
		userHandler:        userHandler,
		postHandler:        postHandler,
		interactionHandler: interactionHandler,
		searchHandler:      searchHandler,
		adminHandler:       adminHandler,
		uploadHandler:      uploadHandler,
		healthHandler:      healthHandler,
		jwtManager:         jwtManager,
		logger:             logger,
		config:             cfg,
	}
}

// Setup sets up all routes
func (r *Router) Setup() *gin.Engine {
	// Create Gin engine
	engine := gin.New()

	// Add middleware
	engine.Use(gin.Recovery())
	engine.Use(middleware.LoggerMiddleware(r.logger))
	engine.Use(middleware.CORSMiddleware(r.config.CORS.AllowedOrigins))

	// Health check endpoint
	engine.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status": "healthy",
		})
	})

	// A6: Readiness check endpoint
	engine.GET("/ready", r.healthHandler.Readiness)

	// API v1 routes
	v1 := engine.Group("/api/v1")
	{
		// Auth routes (public)
		auth := v1.Group("/auth")
		{
			auth.POST("/sms/send", r.authHandler.SendCode)
			auth.POST("/sms/verify", r.authHandler.VerifyCode)
		}

		// Admin auth routes (public)
		adminAuth := v1.Group("/admin/auth")
		{
			adminAuth.POST("/login", r.authHandler.AdminLogin)
		}

		// User routes (protected)
		users := v1.Group("/users")
		users.Use(middleware.AuthMiddleware(r.jwtManager))
		{
			users.GET("/me", r.userHandler.GetMe)
			users.PUT("/me", r.userHandler.UpdateMe)
			users.GET("/:id", r.userHandler.GetUser)
			users.GET("/:id/posts", r.userHandler.GetUserPosts)
		}

		// Post routes
		posts := v1.Group("/posts")
		{
			// Public routes
			posts.GET("", r.postHandler.GetPosts)
			posts.GET("/:id", r.postHandler.GetPost)

			// Protected routes
			protected := posts.Group("")
			protected.Use(middleware.AuthMiddleware(r.jwtManager))
			{
				protected.POST("", r.postHandler.CreatePost)
				protected.DELETE("/:id", r.postHandler.DeletePost)

				// Interaction routes
				protected.POST("/:id/like", r.interactionHandler.ToggleLike)
				protected.GET("/:id/comments", r.interactionHandler.GetComments)
				protected.POST("/:id/comments", r.interactionHandler.CreateComment)
			}
		}

		// Comment routes (protected)
		comments := v1.Group("/comments")
		comments.Use(middleware.AuthMiddleware(r.jwtManager))
		{
			comments.DELETE("/:id", r.interactionHandler.DeleteComment)
		}

		// Search routes (public)
		search := v1.Group("/search")
		{
			search.GET("", r.searchHandler.SearchPosts)
		}

		// Hashtag routes (public)
		hashtags := v1.Group("/hashtags")
		{
			hashtags.GET("/trending", r.searchHandler.GetTrendingHashtags)
			hashtags.GET("/:name/posts", r.searchHandler.GetPostsByHashtag)
		}

		// Upload routes (protected)
		upload := v1.Group("/upload")
		upload.Use(middleware.AuthMiddleware(r.jwtManager))
		{
			upload.POST("/image", r.uploadHandler.UploadImage)
			upload.POST("/video", r.uploadHandler.UploadVideo)
		}

		// Admin routes (protected + admin only)
		admin := v1.Group("/admin")
		admin.Use(middleware.AuthMiddleware(r.jwtManager))
		admin.Use(middleware.AdminMiddleware())
		{
			// Stats
			admin.GET("/stats", r.adminHandler.GetStats)

			// Posts management
			admin.GET("/posts", r.adminHandler.GetPosts)
			admin.GET("/posts/:id", r.adminHandler.GetPost)
			admin.PUT("/posts/:id/visibility", r.adminHandler.UpdatePostVisibility)
			admin.PUT("/posts/:id/label", r.adminHandler.UpdatePostLabel)
			admin.DELETE("/posts/:id", r.adminHandler.DeletePost)

			// Users management
			admin.GET("/users", r.adminHandler.GetUsers)
			admin.GET("/users/:id", r.adminHandler.GetUser)
		}
	}

	return engine
}
