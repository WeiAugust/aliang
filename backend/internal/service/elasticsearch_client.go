package service

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"

	"go.uber.org/zap"

	"github.com/WeiAugust/aliang/backend/internal/model"
)

// SearchEngine defines search index capabilities.
type SearchEngine interface {
	EnsureIndex(ctx context.Context) error
	IndexPost(ctx context.Context, post *model.Post) error
	DeletePost(ctx context.Context, postID int64) error
	SearchPostIDs(ctx context.Context, query string, offset, limit int) ([]int64, error)
}

type elasticsearchClient struct {
	baseURL    string
	username   string
	password   string
	index      string
	httpClient *http.Client
	logger     *zap.Logger
}

type esPostDocument struct {
	ID         int64     `json:"id"`
	UserID     int64     `json:"user_id"`
	Title      string    `json:"title"`
	Content    string    `json:"content"`
	Visibility string    `json:"visibility"`
	Label      string    `json:"label"`
	CreatedAt  time.Time `json:"created_at"`
	UpdatedAt  time.Time `json:"updated_at"`
}

type esSearchResponse struct {
	Hits struct {
		Hits []struct {
			Source esPostDocument `json:"_source"`
		} `json:"hits"`
	} `json:"hits"`
}

// NewElasticsearchClient creates a search engine backed by Elasticsearch.
func NewElasticsearchClient(
	baseURL string,
	username string,
	password string,
	index string,
	timeout time.Duration,
	logger *zap.Logger,
) SearchEngine {
	if logger == nil {
		logger = zap.NewNop()
	}

	return &elasticsearchClient{
		baseURL:  strings.TrimRight(baseURL, "/"),
		username: strings.TrimSpace(username),
		password: password,
		index:    strings.TrimSpace(index),
		httpClient: &http.Client{
			Timeout: timeout,
		},
		logger: logger,
	}
}

func (c *elasticsearchClient) EnsureIndex(ctx context.Context) error {
	existsReq, err := c.newRequest(ctx, http.MethodHead, "/"+c.index, nil)
	if err != nil {
		return err
	}

	existsResp, err := c.httpClient.Do(existsReq)
	if err != nil {
		return fmt.Errorf("failed to check index existence: %w", err)
	}
	defer existsResp.Body.Close()

	if existsResp.StatusCode == http.StatusOK {
		return nil
	}

	if existsResp.StatusCode != http.StatusNotFound {
		body, _ := io.ReadAll(existsResp.Body)
		return fmt.Errorf("unexpected index check status: %d body=%s", existsResp.StatusCode, strings.TrimSpace(string(body)))
	}

	mapping := map[string]any{
		"mappings": map[string]any{
			"properties": map[string]any{
				"id":         map[string]any{"type": "long"},
				"user_id":    map[string]any{"type": "long"},
				"title":      map[string]any{"type": "text", "analyzer": "standard"},
				"content":    map[string]any{"type": "text", "analyzer": "standard"},
				"visibility": map[string]any{"type": "keyword"},
				"label":      map[string]any{"type": "keyword"},
				"created_at": map[string]any{"type": "date"},
				"updated_at": map[string]any{"type": "date"},
			},
		},
	}

	body, err := json.Marshal(mapping)
	if err != nil {
		return fmt.Errorf("failed to marshal mapping: %w", err)
	}

	createReq, err := c.newRequest(ctx, http.MethodPut, "/"+c.index, bytes.NewReader(body))
	if err != nil {
		return err
	}

	createResp, err := c.httpClient.Do(createReq)
	if err != nil {
		return fmt.Errorf("failed to create index: %w", err)
	}
	defer createResp.Body.Close()

	if createResp.StatusCode >= 200 && createResp.StatusCode < 300 {
		c.logger.Info("Elasticsearch index created", zap.String("index", c.index))
		return nil
	}

	createBody, _ := io.ReadAll(createResp.Body)
	return fmt.Errorf("failed to create index status=%d body=%s", createResp.StatusCode, strings.TrimSpace(string(createBody)))
}

func (c *elasticsearchClient) IndexPost(ctx context.Context, post *model.Post) error {
	doc := esPostDocument{
		ID:         post.ID,
		UserID:     post.UserID,
		Title:      post.Title,
		Content:    post.Content,
		Visibility: post.Visibility,
		Label:      post.Label,
		CreatedAt:  post.CreatedAt,
		UpdatedAt:  post.UpdatedAt,
	}

	body, err := json.Marshal(doc)
	if err != nil {
		return fmt.Errorf("failed to marshal post document: %w", err)
	}

	path := fmt.Sprintf("/%s/_doc/%d", c.index, post.ID)
	req, err := c.newRequest(ctx, http.MethodPut, path, bytes.NewReader(body))
	if err != nil {
		return err
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("failed to index post: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 200 && resp.StatusCode < 300 {
		return nil
	}

	respBody, _ := io.ReadAll(resp.Body)
	return fmt.Errorf("failed to index post status=%d body=%s", resp.StatusCode, strings.TrimSpace(string(respBody)))
}

func (c *elasticsearchClient) DeletePost(ctx context.Context, postID int64) error {
	path := fmt.Sprintf("/%s/_doc/%d", c.index, postID)
	req, err := c.newRequest(ctx, http.MethodDelete, path, nil)
	if err != nil {
		return err
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("failed to delete post document: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusNotFound {
		return nil
	}

	if resp.StatusCode >= 200 && resp.StatusCode < 300 {
		return nil
	}

	respBody, _ := io.ReadAll(resp.Body)
	return fmt.Errorf("failed to delete post document status=%d body=%s", resp.StatusCode, strings.TrimSpace(string(respBody)))
}

func (c *elasticsearchClient) SearchPostIDs(ctx context.Context, query string, offset, limit int) ([]int64, error) {
	payload := map[string]any{
		"from": offset,
		"size": limit,
		"sort": []map[string]any{
			{"created_at": map[string]any{"order": "desc"}},
		},
		"query": map[string]any{
			"bool": map[string]any{
				"must": []map[string]any{
					{
						"multi_match": map[string]any{
							"query":     query,
							"fields":    []string{"title^2", "content"},
							"fuzziness": "AUTO",
						},
					},
				},
				"filter": []map[string]any{
					{"term": map[string]any{"visibility": "public"}},
				},
			},
		},
		"_source": []string{"id"},
	}

	body, err := json.Marshal(payload)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal search payload: %w", err)
	}

	path := fmt.Sprintf("/%s/_search", c.index)
	req, err := c.newRequest(ctx, http.MethodPost, path, bytes.NewReader(body))
	if err != nil {
		return nil, err
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to execute search request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		respBody, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("search request failed status=%d body=%s", resp.StatusCode, strings.TrimSpace(string(respBody)))
	}

	var parsed esSearchResponse
	if err := json.NewDecoder(resp.Body).Decode(&parsed); err != nil {
		return nil, fmt.Errorf("failed to decode search response: %w", err)
	}

	ids := make([]int64, 0, len(parsed.Hits.Hits))
	for _, hit := range parsed.Hits.Hits {
		ids = append(ids, hit.Source.ID)
	}

	return ids, nil
}

func (c *elasticsearchClient) newRequest(ctx context.Context, method, path string, body io.Reader) (*http.Request, error) {
	u, err := url.JoinPath(c.baseURL, path)
	if err != nil {
		return nil, fmt.Errorf("failed to build elasticsearch URL: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, method, u, body)
	if err != nil {
		return nil, fmt.Errorf("failed to build elasticsearch request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	if c.username != "" {
		req.SetBasicAuth(c.username, c.password)
	}

	return req, nil
}
