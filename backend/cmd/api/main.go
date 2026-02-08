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

	"go.uber.org/zap"

	"github.com/WeiAugust/aliang/backend/internal/config"
	"github.com/WeiAugust/aliang/backend/internal/handler"
	"github.com/WeiAugust/aliang/backend/internal/pkg"
	"github.com/WeiAugust/aliang/backend/internal/repository"
	"github.com/WeiAugust/aliang/backend/internal/router"
	"github.com/WeiAugust/aliang/backend/internal/service"
)

func main() {
	// Initialize logger
	logger, err := zap.NewProduction()
	if err != nil {
		log.Fatalf("Failed to initialize logger: %v", err)
	}
	defer logger.Sync()

	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		logger.Fatal("Failed to load configuration", zap.Error(err))
	}

	// Initialize database
	db, err := config.InitDB(&cfg.Database)
	if err != nil {
		logger.Fatal("Failed to initialize database", zap.Error(err))
	}
	defer config.CloseDB(db)

	// Initialize Redis
	redisClient, err := config.InitRedis(&cfg.Redis)
	if err != nil {
		logger.Fatal("Failed to initialize Redis", zap.Error(err))
	}
	defer config.CloseRedis(redisClient)

	// Initialize MinIO
	minioClient, err := config.InitMinIO(&cfg.MinIO)
	if err != nil {
		logger.Fatal("Failed to initialize MinIO", zap.Error(err))
	}

	// Initialize JWT manager
	jwtManager, err := pkg.NewJWTManager(cfg.JWT.Secret, cfg.JWT.Expiry)
	if err != nil {
		logger.Fatal("Failed to initialize JWT manager", zap.Error(err))
	}

	// Initialize SMS service
	smsService := pkg.NewSMSService(redisClient, cfg.SMS.MockEnabled, cfg.SMS.MockCode)

	// Initialize repositories
	userRepo := repository.NewUserRepository(db)
	postRepo := repository.NewPostRepository(db)
	commentRepo := repository.NewCommentRepository(db)
	likeRepo := repository.NewLikeRepository(db)
	hashtagRepo := repository.NewHashtagRepository(db)
	postHashtagRepo := repository.NewPostHashtagRepository(db)
	postMediaRepo := repository.NewPostMediaRepository(db)

	// Initialize services
	authService := service.NewAuthService(userRepo, jwtManager, smsService)
	userService := service.NewUserService(userRepo)
	postService := service.NewPostService(postRepo, hashtagRepo, postHashtagRepo, postMediaRepo)
	interactionService := service.NewInteractionService(likeRepo, commentRepo, postRepo)
	searchService := service.NewSearchService(postRepo, hashtagRepo, postHashtagRepo)
	storageService := service.NewStorageService(minioClient, cfg.MinIO.Bucket, cfg.MinIO.Endpoint)

	// Initialize handlers
	authHandler := handler.NewAuthHandler(authService)
	userHandler := handler.NewUserHandler(userService, postService)
	postHandler := handler.NewPostHandler(postService)
	interactionHandler := handler.NewInteractionHandler(interactionService)
	searchHandler := handler.NewSearchHandler(searchService)
	adminHandler := handler.NewAdminHandler(userService, postService, interactionService)
	uploadHandler := handler.NewUploadHandler(storageService, logger)
	healthHandler := handler.NewHealthHandler(db, redisClient, cfg)

	// Initialize router
	r := router.NewRouter(
		authHandler,
		userHandler,
		postHandler,
		interactionHandler,
		searchHandler,
		adminHandler,
		uploadHandler,
		healthHandler,
		jwtManager,
		logger,
		cfg,
	)

	// Setup routes
	engine := r.Setup()

	// Create HTTP server
	addr := fmt.Sprintf("%s:%s", cfg.Server.Host, cfg.Server.Port)
	srv := &http.Server{
		Addr:    addr,
		Handler: engine,
	}

	// Start server in a goroutine
	go func() {
		logger.Info("Starting server", zap.String("address", addr))
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal("Failed to start server", zap.Error(err))
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Info("Shutting down server...")

	// Graceful shutdown with 5 second timeout
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		logger.Fatal("Server forced to shutdown", zap.Error(err))
	}

	logger.Info("Server exited")
}
