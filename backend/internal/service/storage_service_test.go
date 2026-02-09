package service

import (
	"bytes"
	"context"
	"errors"
	"io"
	"strings"
	"testing"

	"github.com/minio/minio-go/v7"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type mockMinioClient struct {
	putObjectFunc    func(ctx context.Context, bucketName, objectName string, reader io.Reader, objectSize int64, opts minio.PutObjectOptions) (minio.UploadInfo, error)
	removeObjectFunc func(ctx context.Context, bucketName, objectName string, opts minio.RemoveObjectOptions) error
}

func (m *mockMinioClient) PutObject(ctx context.Context, bucketName, objectName string, reader io.Reader, objectSize int64, opts minio.PutObjectOptions) (minio.UploadInfo, error) {
	if m.putObjectFunc == nil {
		return minio.UploadInfo{}, errors.New("put object mock not configured")
	}

	return m.putObjectFunc(ctx, bucketName, objectName, reader, objectSize, opts)
}

func (m *mockMinioClient) RemoveObject(ctx context.Context, bucketName, objectName string, opts minio.RemoveObjectOptions) error {
	if m.removeObjectFunc == nil {
		return errors.New("remove object mock not configured")
	}

	return m.removeObjectFunc(ctx, bucketName, objectName, opts)
}

func TestStorageService_UploadImage(t *testing.T) {
	t.Run("success with png", func(t *testing.T) {
		mockClient := &mockMinioClient{
			putObjectFunc: func(_ context.Context, bucketName, objectName string, reader io.Reader, objectSize int64, opts minio.PutObjectOptions) (minio.UploadInfo, error) {
				assert.Equal(t, "media", bucketName)
				assert.Contains(t, objectName, "images/")
				assert.True(t, strings.HasSuffix(objectName, "_cat.png"))
				assert.Equal(t, int64(len("png data")), objectSize)
				assert.Equal(t, "image/png", opts.ContentType)

				content, err := io.ReadAll(reader)
				require.NoError(t, err)
				assert.Equal(t, "png data", string(content))

				return minio.UploadInfo{}, nil
			},
		}

		s := newStorageServiceWithClient(mockClient, "media", "http://localhost:9000")
		url, err := s.UploadImage(context.Background(), "cat.png", bytes.NewReader([]byte("png data")), int64(len("png data")))

		require.NoError(t, err)
		assert.Contains(t, url, "http://localhost:9000/media/images/")
		assert.True(t, strings.HasSuffix(url, "_cat.png"))
	})

	t.Run("endpoint without scheme normalized", func(t *testing.T) {
		mockClient := &mockMinioClient{
			putObjectFunc: func(_ context.Context, _ string, objectName string, _ io.Reader, _ int64, _ minio.PutObjectOptions) (minio.UploadInfo, error) {
				assert.Contains(t, objectName, "images/")
				return minio.UploadInfo{}, nil
			},
		}

		s := newStorageServiceWithClient(mockClient, "media", "localhost:9000")
		url, err := s.UploadImage(context.Background(), "cat.jpg", bytes.NewReader([]byte("jpg")), 3)

		require.NoError(t, err)
		assert.Contains(t, url, "http://localhost:9000/media/images/")
	})

	t.Run("uppercase extension handled", func(t *testing.T) {
		mockClient := &mockMinioClient{
			putObjectFunc: func(_ context.Context, _ string, objectName string, _ io.Reader, _ int64, opts minio.PutObjectOptions) (minio.UploadInfo, error) {
				assert.True(t, strings.HasSuffix(objectName, "_flower.webp"))
				assert.Equal(t, "image/webp", opts.ContentType)
				return minio.UploadInfo{}, nil
			},
		}

		s := newStorageServiceWithClient(mockClient, "media", "http://localhost:9000")
		_, err := s.UploadImage(context.Background(), "flower.WEBP", bytes.NewReader([]byte("webp data")), int64(len("webp data")))

		require.NoError(t, err)
	})

	t.Run("no extension uses jpeg default", func(t *testing.T) {
		mockClient := &mockMinioClient{
			putObjectFunc: func(_ context.Context, _ string, objectName string, _ io.Reader, _ int64, opts minio.PutObjectOptions) (minio.UploadInfo, error) {
				assert.True(t, strings.HasSuffix(objectName, "_avatar"))
				assert.Equal(t, "image/jpeg", opts.ContentType)
				return minio.UploadInfo{}, nil
			},
		}

		s := newStorageServiceWithClient(mockClient, "media", "http://localhost:9000")
		_, err := s.UploadImage(context.Background(), "avatar", bytes.NewReader([]byte("raw")), 3)

		require.NoError(t, err)
	})

	t.Run("put object error", func(t *testing.T) {
		mockClient := &mockMinioClient{
			putObjectFunc: func(_ context.Context, _ string, _ string, _ io.Reader, _ int64, _ minio.PutObjectOptions) (minio.UploadInfo, error) {
				return minio.UploadInfo{}, errors.New("put failed")
			},
		}

		s := newStorageServiceWithClient(mockClient, "media", "http://localhost:9000")
		_, err := s.UploadImage(context.Background(), "cat.jpg", bytes.NewReader([]byte("jpg")), 3)

		require.Error(t, err)
		assert.Contains(t, err.Error(), "failed to upload image")
		assert.Contains(t, err.Error(), "put failed")
	})
}

func TestStorageService_UploadVideo(t *testing.T) {
	t.Run("success with mov", func(t *testing.T) {
		mockClient := &mockMinioClient{
			putObjectFunc: func(_ context.Context, bucketName, objectName string, reader io.Reader, objectSize int64, opts minio.PutObjectOptions) (minio.UploadInfo, error) {
				assert.Equal(t, "media", bucketName)
				assert.Contains(t, objectName, "videos/")
				assert.True(t, strings.HasSuffix(objectName, "_clip.mov"))
				assert.Equal(t, int64(len("mov data")), objectSize)
				assert.Equal(t, "video/quicktime", opts.ContentType)

				content, err := io.ReadAll(reader)
				require.NoError(t, err)
				assert.Equal(t, "mov data", string(content))

				return minio.UploadInfo{}, nil
			},
		}

		s := newStorageServiceWithClient(mockClient, "media", "http://localhost:9000")
		url, err := s.UploadVideo(context.Background(), "clip.mov", bytes.NewReader([]byte("mov data")), int64(len("mov data")))

		require.NoError(t, err)
		assert.Contains(t, url, "http://localhost:9000/media/videos/")
		assert.True(t, strings.HasSuffix(url, "_clip.mov"))
	})

	t.Run("uppercase extension handled", func(t *testing.T) {
		mockClient := &mockMinioClient{
			putObjectFunc: func(_ context.Context, _ string, objectName string, _ io.Reader, _ int64, opts minio.PutObjectOptions) (minio.UploadInfo, error) {
				assert.True(t, strings.HasSuffix(objectName, "_recording.webm"))
				assert.Equal(t, "video/webm", opts.ContentType)
				return minio.UploadInfo{}, nil
			},
		}

		s := newStorageServiceWithClient(mockClient, "media", "http://localhost:9000")
		_, err := s.UploadVideo(context.Background(), "recording.WEBM", bytes.NewReader([]byte("webm data")), int64(len("webm data")))

		require.NoError(t, err)
	})

	t.Run("put object error", func(t *testing.T) {
		mockClient := &mockMinioClient{
			putObjectFunc: func(_ context.Context, _ string, _ string, _ io.Reader, _ int64, _ minio.PutObjectOptions) (minio.UploadInfo, error) {
				return minio.UploadInfo{}, errors.New("put failed")
			},
		}

		s := newStorageServiceWithClient(mockClient, "media", "http://localhost:9000")
		_, err := s.UploadVideo(context.Background(), "clip.mp4", bytes.NewReader([]byte("mp4")), 3)

		require.Error(t, err)
		assert.Contains(t, err.Error(), "failed to upload video")
		assert.Contains(t, err.Error(), "put failed")
	})
}

func TestStorageService_DeleteFile(t *testing.T) {
	t.Run("success", func(t *testing.T) {
		var removedObject string
		mockClient := &mockMinioClient{
			removeObjectFunc: func(_ context.Context, bucketName, objectName string, _ minio.RemoveObjectOptions) error {
				assert.Equal(t, "media", bucketName)
				removedObject = objectName
				return nil
			},
		}

		s := newStorageServiceWithClient(mockClient, "media", "http://localhost:9000")
		err := s.DeleteFile(context.Background(), "images/test.jpg")

		require.NoError(t, err)
		assert.Equal(t, "images/test.jpg", removedObject)
	})

	t.Run("remove error", func(t *testing.T) {
		mockClient := &mockMinioClient{
			removeObjectFunc: func(_ context.Context, _ string, _ string, _ minio.RemoveObjectOptions) error {
				return errors.New("remove failed")
			},
		}

		s := newStorageServiceWithClient(mockClient, "media", "http://localhost:9000")
		err := s.DeleteFile(context.Background(), "images/test.jpg")

		require.Error(t, err)
		assert.Contains(t, err.Error(), "failed to delete file")
		assert.Contains(t, err.Error(), "remove failed")
	})
}

func TestSplitFileName(t *testing.T) {
	tests := []struct {
		name     string
		filename string
		wantBase string
		wantExt  string
	}{
		{name: "normal", filename: "test.jpg", wantBase: "test", wantExt: ".jpg"},
		{name: "uppercase extension", filename: "test.PNG", wantBase: "test", wantExt: ".png"},
		{name: "no extension", filename: "test", wantBase: "test", wantExt: ""},
		{name: "trailing dot", filename: "test.", wantBase: "test", wantExt: ""},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			base, ext := splitFileName(tt.filename)
			assert.Equal(t, tt.wantBase, base)
			assert.Equal(t, tt.wantExt, ext)
		})
	}
}
