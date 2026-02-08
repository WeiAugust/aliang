package config

import (
	"fmt"
	"log"
	"time"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"

	"github.com/WeiAugust/aliang/backend/internal/model"
)

// InitDB initializes the database connection
func InitDB(cfg *DatabaseConfig) (*gorm.DB, error) {
	// Configure GORM logger
	gormLogger := logger.Default
	if IsDevelopment() {
		gormLogger = logger.Default.LogMode(logger.Info)
	} else {
		gormLogger = logger.Default.LogMode(logger.Error)
	}

	// Open database connection
	db, err := gorm.Open(postgres.Open(cfg.GetDSN()), &gorm.Config{
		Logger: gormLogger,
		NowFunc: func() time.Time {
			return time.Now().UTC()
		},
	})
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	// Get underlying SQL database
	sqlDB, err := db.DB()
	if err != nil {
		return nil, fmt.Errorf("failed to get database instance: %w", err)
	}

	// Set connection pool settings
	sqlDB.SetMaxIdleConns(10)
	sqlDB.SetMaxOpenConns(100)
	sqlDB.SetConnMaxLifetime(time.Hour)

	// Auto-migrate models (optional, migrations are preferred)
	if IsDevelopment() {
		if err := db.AutoMigrate(
			&model.User{},
			&model.Post{},
			&model.PostMedia{},
			&model.Comment{},
			&model.Like{},
			&model.Hashtag{},
			&model.PostHashtag{},
		); err != nil {
			return nil, fmt.Errorf("failed to auto-migrate models: %w", err)
		}
		log.Println("Database auto-migration completed")
	}

	log.Println("Database connection established")
	return db, nil
}

// CloseDB closes the database connection
func CloseDB(db *gorm.DB) error {
	sqlDB, err := db.DB()
	if err != nil {
		return fmt.Errorf("failed to get database instance: %w", err)
	}
	return sqlDB.Close()
}
