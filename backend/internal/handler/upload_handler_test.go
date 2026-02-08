package handler

import (
	"bytes"
	"context"
	"errors"
	"io"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"
)

type mockUploadStorage struct {
	uploadImageFunc func(ctx context.Context, filename string, reader io.Reader, size int64) (string, error)
	uploadVideoFunc func(ctx context.Context, filename string, reader io.Reader, size int64) (string, error)
}

func (m *mockUploadStorage) UploadImage(ctx context.Context, filename string, reader io.Reader, size int64) (string, error) {
	if m.uploadImageFunc == nil {
		return "", errors.New("upload image mock not configured")
	}

	return m.uploadImageFunc(ctx, filename, reader, size)
}

func (m *mockUploadStorage) UploadVideo(ctx context.Context, filename string, reader io.Reader, size int64) (string, error) {
	if m.uploadVideoFunc == nil {
		return "", errors.New("upload video mock not configured")
	}

	return m.uploadVideoFunc(ctx, filename, reader, size)
}

func newMultipartRequest(t *testing.T, filename string, content []byte) *http.Request {
	t.Helper()

	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)
	part, err := writer.CreateFormFile("file", filename)
	require.NoError(t, err)

	_, err = part.Write(content)
	require.NoError(t, err)
	require.NoError(t, writer.Close())

	req := httptest.NewRequest(http.MethodPost, "/upload", body)
	req.Header.Set("Content-Type", writer.FormDataContentType())
	return req
}

func TestUploadHandler_UploadImage(t *testing.T) {
	gin.SetMode(gin.TestMode)

	t.Run("success", func(t *testing.T) {
		expectedURL := "http://localhost:9000/media/images/ok.jpg"
		storage := &mockUploadStorage{
			uploadImageFunc: func(_ context.Context, filename string, reader io.Reader, size int64) (string, error) {
				assert.Equal(t, "test.jpg", filename)
				assert.Equal(t, int64(len("fake image content")), size)

				readBytes, err := io.ReadAll(reader)
				require.NoError(t, err)
				assert.Equal(t, "fake image content", string(readBytes))

				return expectedURL, nil
			},
		}

		handler := NewUploadHandler(storage, zap.NewNop())
		w := httptest.NewRecorder()
		c, _ := gin.CreateTestContext(w)
		c.Request = newMultipartRequest(t, "test.jpg", []byte("fake image content"))

		handler.UploadImage(c)

		assert.Equal(t, http.StatusOK, w.Code)
		assert.Contains(t, w.Body.String(), `"success":true`)
		assert.Contains(t, w.Body.String(), expectedURL)
	})

	t.Run("invalid file type", func(t *testing.T) {
		storage := &mockUploadStorage{}
		handler := NewUploadHandler(storage, zap.NewNop())

		w := httptest.NewRecorder()
		c, _ := gin.CreateTestContext(w)
		c.Request = newMultipartRequest(t, "test.txt", []byte("text content"))

		handler.UploadImage(c)

		assert.Equal(t, http.StatusBadRequest, w.Code)
		assert.Contains(t, w.Body.String(), "Invalid file type")
	})

	t.Run("storage failure", func(t *testing.T) {
		storage := &mockUploadStorage{
			uploadImageFunc: func(_ context.Context, _ string, _ io.Reader, _ int64) (string, error) {
				return "", errors.New("storage down")
			},
		}
		handler := NewUploadHandler(storage, zap.NewNop())

		w := httptest.NewRecorder()
		c, _ := gin.CreateTestContext(w)
		c.Request = newMultipartRequest(t, "test.jpg", []byte("fake image content"))

		handler.UploadImage(c)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		assert.Contains(t, w.Body.String(), "Failed to upload file")
	})

	t.Run("missing file", func(t *testing.T) {
		storage := &mockUploadStorage{}
		handler := NewUploadHandler(storage, zap.NewNop())

		w := httptest.NewRecorder()
		c, _ := gin.CreateTestContext(w)
		c.Request = httptest.NewRequest(http.MethodPost, "/upload", strings.NewReader(""))
		c.Request.Header.Set("Content-Type", "multipart/form-data")

		handler.UploadImage(c)

		assert.Equal(t, http.StatusBadRequest, w.Code)
		assert.Contains(t, w.Body.String(), "No file uploaded")
	})
}

func TestUploadHandler_UploadVideo(t *testing.T) {
	gin.SetMode(gin.TestMode)

	t.Run("success", func(t *testing.T) {
		expectedURL := "http://localhost:9000/media/videos/ok.mp4"
		storage := &mockUploadStorage{
			uploadVideoFunc: func(_ context.Context, filename string, reader io.Reader, size int64) (string, error) {
				assert.Equal(t, "test.mp4", filename)
				assert.Equal(t, int64(len("fake video content")), size)

				readBytes, err := io.ReadAll(reader)
				require.NoError(t, err)
				assert.Equal(t, "fake video content", string(readBytes))

				return expectedURL, nil
			},
		}

		handler := NewUploadHandler(storage, zap.NewNop())
		w := httptest.NewRecorder()
		c, _ := gin.CreateTestContext(w)
		c.Request = newMultipartRequest(t, "test.mp4", []byte("fake video content"))

		handler.UploadVideo(c)

		assert.Equal(t, http.StatusOK, w.Code)
		assert.Contains(t, w.Body.String(), `"success":true`)
		assert.Contains(t, w.Body.String(), expectedURL)
	})

	t.Run("invalid file type", func(t *testing.T) {
		storage := &mockUploadStorage{}
		handler := NewUploadHandler(storage, zap.NewNop())

		w := httptest.NewRecorder()
		c, _ := gin.CreateTestContext(w)
		c.Request = newMultipartRequest(t, "test.txt", []byte("text content"))

		handler.UploadVideo(c)

		assert.Equal(t, http.StatusBadRequest, w.Code)
		assert.Contains(t, w.Body.String(), "Invalid file type")
	})

	t.Run("storage failure", func(t *testing.T) {
		storage := &mockUploadStorage{
			uploadVideoFunc: func(_ context.Context, _ string, _ io.Reader, _ int64) (string, error) {
				return "", errors.New("storage down")
			},
		}
		handler := NewUploadHandler(storage, zap.NewNop())

		w := httptest.NewRecorder()
		c, _ := gin.CreateTestContext(w)
		c.Request = newMultipartRequest(t, "test.mp4", []byte("fake video content"))

		handler.UploadVideo(c)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		assert.Contains(t, w.Body.String(), "Failed to upload file")
	})
}

func TestIsImageFile(t *testing.T) {
	tests := []struct {
		filename string
		want     bool
	}{
		{"test.jpg", true},
		{"test.jpeg", true},
		{"test.png", true},
		{"test.gif", true},
		{"test.webp", true},
		{"test.JPG", true},
		{"test.txt", false},
		{"test.mp4", false},
		{"test", false},
		{"test.", false},
	}

	for _, tt := range tests {
		t.Run(tt.filename, func(t *testing.T) {
			got := isImageFile(tt.filename)
			assert.Equal(t, tt.want, got)
		})
	}
}

func TestIsVideoFile(t *testing.T) {
	tests := []struct {
		filename string
		want     bool
	}{
		{"test.mp4", true},
		{"test.mov", true},
		{"test.avi", true},
		{"test.webm", true},
		{"test.MP4", true},
		{"test.jpg", false},
		{"test.txt", false},
		{"test", false},
		{"test.", false},
	}

	for _, tt := range tests {
		t.Run(tt.filename, func(t *testing.T) {
			got := isVideoFile(tt.filename)
			assert.Equal(t, tt.want, got)
		})
	}
}
