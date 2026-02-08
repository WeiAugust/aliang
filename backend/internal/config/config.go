package config

import (
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/spf13/viper"
)

// Config holds all configuration for the application
type Config struct {
	Server   ServerConfig
	Database DatabaseConfig
	Redis    RedisConfig
	MinIO    MinIOConfig
	JWT      JWTConfig
	Admin    AdminConfig
	SMS      SMSConfig
	Upload   UploadConfig
	CORS     CORSConfig
}

// ServerConfig holds server configuration
type ServerConfig struct {
	Port string
	Host string
}

// DatabaseConfig holds database configuration
type DatabaseConfig struct {
	Host     string
	Port     string
	User     string
	Password string
	Name     string
	SSLMode  string
}

// RedisConfig holds Redis configuration
type RedisConfig struct {
	Host     string
	Port     string
	Password string
	DB       int
}

// MinIOConfig holds MinIO configuration
type MinIOConfig struct {
	Endpoint  string
	AccessKey string
	SecretKey string
	UseSSL    bool
	Bucket    string
}

// JWTConfig holds JWT configuration
type JWTConfig struct {
	Secret string
	Expiry string
}

// AdminConfig holds admin configuration
type AdminConfig struct {
	Username string
	Password string
}

// SMSConfig holds SMS configuration
type SMSConfig struct {
	MockEnabled bool
	MockCode    string
}

// UploadConfig holds upload configuration
type UploadConfig struct {
	MaxSize       int64
	AllowedImages []string
	AllowedVideos []string
}

// CORSConfig holds CORS configuration
type CORSConfig struct {
	AllowedOrigins []string
}

// parseStringSlice parses a comma-separated string into a slice
func parseStringSlice(s string) []string {
	if s == "" {
		return nil
	}
	parts := strings.Split(s, ",")
	result := make([]string, 0, len(parts))
	for _, p := range parts {
		trimmed := strings.TrimSpace(p)
		if trimmed != "" {
			result = append(result, trimmed)
		}
	}
	return result
}

// Load loads configuration from environment variables and .env file
func Load() (*Config, error) {
	// Set default values
	viper.SetDefault("SERVER_PORT", "8080")
	viper.SetDefault("SERVER_HOST", "0.0.0.0")
	viper.SetDefault("DB_HOST", "localhost")
	viper.SetDefault("DB_PORT", "5432")
	viper.SetDefault("DB_SSL_MODE", "disable")
	viper.SetDefault("REDIS_HOST", "localhost")
	viper.SetDefault("REDIS_PORT", "6379")
	viper.SetDefault("REDIS_DB", 0)
	viper.SetDefault("MINIO_USE_SSL", false)
	viper.SetDefault("MINIO_BUCKET", "aliang-media")
	viper.SetDefault("JWT_EXPIRY", "24h")
	viper.SetDefault("SMS_MOCK_ENABLED", true)
	viper.SetDefault("SMS_MOCK_CODE", "123456")
	viper.SetDefault("UPLOAD_MAX_SIZE", 10485760) // 10MB

	// Load .env file if it exists
	viper.SetConfigFile(".env")
	viper.SetConfigType("env")
	if err := viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			return nil, fmt.Errorf("failed to read config file: %w", err)
		}
		log.Println("No .env file found, using environment variables")
	}

	// Read from environment variables
	viper.AutomaticEnv()

	// Build config struct
	config := &Config{
		Server: ServerConfig{
			Port: viper.GetString("SERVER_PORT"),
			Host: viper.GetString("SERVER_HOST"),
		},
		Database: DatabaseConfig{
			Host:     viper.GetString("DB_HOST"),
			Port:     viper.GetString("DB_PORT"),
			User:     viper.GetString("DB_USER"),
			Password: viper.GetString("DB_PASSWORD"),
			Name:     viper.GetString("DB_NAME"),
			SSLMode:  viper.GetString("DB_SSL_MODE"),
		},
		Redis: RedisConfig{
			Host:     viper.GetString("REDIS_HOST"),
			Port:     viper.GetString("REDIS_PORT"),
			Password: viper.GetString("REDIS_PASSWORD"),
			DB:       viper.GetInt("REDIS_DB"),
		},
		MinIO: MinIOConfig{
			Endpoint:  viper.GetString("MINIO_ENDPOINT"),
			AccessKey: viper.GetString("MINIO_ACCESS_KEY"),
			SecretKey: viper.GetString("MINIO_SECRET_KEY"),
			UseSSL:    viper.GetBool("MINIO_USE_SSL"),
			Bucket:    viper.GetString("MINIO_BUCKET"),
		},
		JWT: JWTConfig{
			Secret: viper.GetString("JWT_SECRET"),
			Expiry: viper.GetString("JWT_EXPIRY"),
		},
		Admin: AdminConfig{
			Username: viper.GetString("ADMIN_USERNAME"),
			Password: viper.GetString("ADMIN_PASSWORD"),
		},
		SMS: SMSConfig{
			MockEnabled: viper.GetBool("SMS_MOCK_ENABLED"),
			MockCode:    viper.GetString("SMS_MOCK_CODE"),
		},
		Upload: UploadConfig{
			MaxSize:       viper.GetInt64("UPLOAD_MAX_SIZE"),
			AllowedImages: viper.GetStringSlice("UPLOAD_ALLOWED_IMAGES"),
			AllowedVideos: viper.GetStringSlice("UPLOAD_ALLOWED_VIDEOS"),
		},
		CORS: CORSConfig{
			AllowedOrigins: parseStringSlice(viper.GetString("CORS_ALLOWED_ORIGINS")),
		},
	}

	// Validate required fields
	if config.Database.User == "" {
		return nil, fmt.Errorf("DB_USER is required")
	}
	if config.Database.Password == "" {
		return nil, fmt.Errorf("DB_PASSWORD is required")
	}
	if config.Database.Name == "" {
		return nil, fmt.Errorf("DB_NAME is required")
	}
	if config.JWT.Secret == "" {
		return nil, fmt.Errorf("JWT_SECRET is required")
	}

	return config, nil
}

// GetDSN returns the database connection string
func (c *DatabaseConfig) GetDSN() string {
	return fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
		c.Host, c.Port, c.User, c.Password, c.Name, c.SSLMode,
	)
}

// GetRedisAddr returns the Redis address
func (c *RedisConfig) GetRedisAddr() string {
	return fmt.Sprintf("%s:%s", c.Host, c.Port)
}

// MustLoad loads configuration and panics on error
func MustLoad() *Config {
	config, err := Load()
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}
	return config
}

// IsDevelopment returns true if running in development mode
func IsDevelopment() bool {
	return os.Getenv("GIN_MODE") != "release"
}
