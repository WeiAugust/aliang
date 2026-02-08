package service

import (
	"context"
	"fmt"
	"io"
	"path/filepath"
	"strings"
	"time"

	"github.com/minio/minio-go/v7"
)

type minioClientAPI interface {
	PutObject(ctx context.Context, bucketName, objectName string, reader io.Reader, objectSize int64, opts minio.PutObjectOptions) (minio.UploadInfo, error)
	RemoveObject(ctx context.Context, bucketName, objectName string, opts minio.RemoveObjectOptions) error
}

// StorageService handles file storage operations
type StorageService struct {
	minioClient minioClientAPI
	bucket      string
	endpoint    string
}

// NewStorageService creates a new storage service
func NewStorageService(minioClient *minio.Client, bucket, endpoint string) *StorageService {
	return newStorageServiceWithClient(minioClient, bucket, endpoint)
}

func newStorageServiceWithClient(minioClient minioClientAPI, bucket, endpoint string) *StorageService {
	return &StorageService{
		minioClient: minioClient,
		bucket:      bucket,
		endpoint:    endpoint,
	}
}

func splitFileName(filename string) (baseName, ext string) {
	ext = strings.ToLower(filepath.Ext(filename))
	if ext == "" || ext == "." {
		return strings.TrimSuffix(filename, "."), ""
	}

	if len(filename) <= len(ext) {
		return filename, ""
	}

	return filename[:len(filename)-len(ext)], ext
}

// UploadImage uploads an image file to storage
func (s *StorageService) UploadImage(ctx context.Context, filename string, reader io.Reader, size int64) (string, error) {
	// Generate unique filename with timestamp
	baseName, ext := splitFileName(filename)
	objectName := fmt.Sprintf("images/%d_%s%s", time.Now().UnixNano(), baseName, ext)

	// Determine content type
	contentType := "image/jpeg"
	switch ext {
	case ".png":
		contentType = "image/png"
	case ".gif":
		contentType = "image/gif"
	case ".webp":
		contentType = "image/webp"
	}

	// Upload to MinIO
	_, err := s.minioClient.PutObject(ctx, s.bucket, objectName, reader, size, minio.PutObjectOptions{
		ContentType: contentType,
	})
	if err != nil {
		return "", fmt.Errorf("failed to upload image: %w", err)
	}

	// Return URL
	url := fmt.Sprintf("%s/%s/%s", s.endpoint, s.bucket, objectName)
	return url, nil
}

// UploadVideo uploads a video file to storage
func (s *StorageService) UploadVideo(ctx context.Context, filename string, reader io.Reader, size int64) (string, error) {
	// Generate unique filename with timestamp
	baseName, ext := splitFileName(filename)
	objectName := fmt.Sprintf("videos/%d_%s%s", time.Now().UnixNano(), baseName, ext)

	// Determine content type
	contentType := "video/mp4"
	switch ext {
	case ".mov":
		contentType = "video/quicktime"
	case ".avi":
		contentType = "video/x-msvideo"
	case ".webm":
		contentType = "video/webm"
	}

	// Upload to MinIO
	_, err := s.minioClient.PutObject(ctx, s.bucket, objectName, reader, size, minio.PutObjectOptions{
		ContentType: contentType,
	})
	if err != nil {
		return "", fmt.Errorf("failed to upload video: %w", err)
	}

	// Return URL
	url := fmt.Sprintf("%s/%s/%s", s.endpoint, s.bucket, objectName)
	return url, nil
}

// DeleteFile deletes a file from storage
func (s *StorageService) DeleteFile(ctx context.Context, objectName string) error {
	err := s.minioClient.RemoveObject(ctx, s.bucket, objectName, minio.RemoveObjectOptions{})
	if err != nil {
		return fmt.Errorf("failed to delete file: %w", err)
	}
	return nil
}
