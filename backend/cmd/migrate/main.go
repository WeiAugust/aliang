package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var (
	upFlag   = flag.Bool("up", false, "Run all pending migrations")
	downFlag = flag.Bool("down", false, "Rollback the last migration")
	stepFlag = flag.Int("step", 1, "Number of migrations to rollback (use with -down)")
)

func main() {
	flag.Parse()

	if !*upFlag && !*downFlag {
		log.Fatal("Usage: go run cmd/migrate/main.go -up | -down [-step=n]")
	}

	cfg := loadConfig()
	db, err := initDB(cfg)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	migrationsDir := "migrations"

	switch {
	case *upFlag:
		runMigrations(db, migrationsDir, "up")
	case *downFlag:
		rollbackMigrations(db, migrationsDir, *stepFlag)
	}

	// Close database connection
	sqlDB, err := db.DB()
	if err != nil {
		log.Printf("Warning: failed to get underlying DB: %v", err)
	} else {
		sqlDB.Close()
	}
}

func loadConfig() *dbConfig {
	return &dbConfig{
		Host:     getEnv("DB_HOST", "localhost"),
		Port:     getEnv("DB_PORT", "5432"),
		User:     getEnv("DB_USER", "aliang"),
		Password: getEnv("DB_PASSWORD", "aliang123"),
		Name:     getEnv("DB_NAME", "aliang"),
		SSLMode:  getEnv("DB_SSL_MODE", "disable"),
	}
}

type dbConfig struct {
	Host     string
	Port     string
	User     string
	Password string
	Name     string
	SSLMode  string
}

func (c *dbConfig) DSN() string {
	return fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
		c.Host, c.Port, c.User, c.Password, c.Name, c.SSLMode,
	)
}

func getEnv(key, defaultValue string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return defaultValue
}

func initDB(cfg *dbConfig) (*gorm.DB, error) {
	db, err := gorm.Open(postgres.Open(cfg.DSN()), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}
	log.Println("Database connection established")
	return db, nil
}

func runMigrations(db *gorm.DB, migrationsDir, direction string) {
	entries, err := os.ReadDir(migrationsDir)
	if err != nil {
		log.Fatalf("Failed to read migrations directory: %v", err)
	}

	var migrationFiles []string
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		if direction == "up" && strings.HasSuffix(entry.Name(), ".up.sql") {
			migrationFiles = append(migrationFiles, entry.Name())
		} else if direction == "down" && strings.HasSuffix(entry.Name(), ".down.sql") {
			migrationFiles = append(migrationFiles, entry.Name())
		}
	}

	// Sort by filename (migration number)
	sort.Strings(migrationFiles)

	if direction == "down" {
		// Reverse order for rollback
		sort.Sort(sort.Reverse(sort.StringSlice(migrationFiles)))
		// Limit to step count
		if len(migrationFiles) > *stepFlag {
			migrationFiles = migrationFiles[:*stepFlag]
		}
	}

	log.Printf("Running %s migrations...\n", direction)

	for _, file := range migrationFiles {
		if err := executeSQLFile(db, filepath.Join(migrationsDir, file)); err != nil {
			log.Fatalf("Failed to execute %s: %v", file, err)
		}
		log.Printf("Executed: %s", file)
	}

	log.Printf("Completed %d migrations\n", len(migrationFiles))
}

func rollbackMigrations(db *gorm.DB, migrationsDir string, step int) {
	runMigrations(db, migrationsDir, "down")
}

func executeSQLFile(db *gorm.DB, filePath string) error {
	content, err := os.ReadFile(filePath)
	if err != nil {
		return fmt.Errorf("failed to read file: %w", err)
	}

	if len(content) == 0 {
		return nil
	}

	// Execute each statement separately
	statements := strings.Split(string(content), ";")
	for _, stmt := range statements {
		stmt = strings.TrimSpace(stmt)
		if stmt == "" {
			continue
		}
		if err := db.Exec(stmt).Error; err != nil {
			if !isIdempotentError(err) {
				return fmt.Errorf("failed to execute statement: %w", err)
			}
		}
	}
	return nil
}

// isIdempotentError checks if an error can be safely ignored when running migrations
func isIdempotentError(err error) bool {
	errStr := err.Error()
	ignorePatterns := []string{
		"already exists",
		"duplicate key",
		"no such column",
		"does not exist",        // for constraints
		"undefined table",       // for DROP
		"cannot drop",          // for dependency constraints
		"already exists",       // for indexes
		"relation",             // for tables/indexes that exist
	}
	for _, pattern := range ignorePatterns {
		if strings.Contains(errStr, pattern) {
			return true
		}
	}
	return false
}
