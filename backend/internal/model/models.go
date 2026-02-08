package model

import (
	"time"
)

// User represents a user account
type User struct {
	ID        int64      `gorm:"primaryKey;autoIncrement" json:"id"`
	Phone     string     `gorm:"uniqueIndex;size:20;not null" json:"phone"`
	Nickname  string     `gorm:"size:50;not null" json:"nickname"`
	AvatarURL string     `gorm:"size:500" json:"avatar_url"`
	Bio       string     `gorm:"size:500" json:"bio"`
	Role      string     `gorm:"size:20;not null;default:user" json:"role"`
	Status    string     `gorm:"size:20;not null;default:active" json:"status"`
	CreatedAt time.Time  `gorm:"not null;default:CURRENT_TIMESTAMP" json:"created_at"`
	UpdatedAt time.Time  `gorm:"not null;default:CURRENT_TIMESTAMP" json:"updated_at"`

	// Associations
	Posts    []Post    `gorm:"foreignKey:UserID" json:"posts,omitempty"`
	Comments []Comment `gorm:"foreignKey:UserID" json:"comments,omitempty"`
	Likes    []Like    `gorm:"foreignKey:UserID" json:"likes,omitempty"`
}

// TableName specifies the table name for User model
func (User) TableName() string {
	return "users"
}

// Post represents a user post
type Post struct {
	ID           int64      `gorm:"primaryKey;autoIncrement" json:"id"`
	UserID       int64      `gorm:"not null;index" json:"user_id"`
	Title        string     `gorm:"size:200;not null" json:"title"`
	Content      string     `gorm:"type:text;not null" json:"content"`
	PostType     string     `gorm:"size:20;not null;default:image" json:"post_type"`
	Visibility   string     `gorm:"size:20;not null;default:public" json:"visibility"`
	Label        string     `gorm:"size:20;not null;default:normal" json:"label"`
	LikeCount    int        `gorm:"not null;default:0" json:"like_count"`
	CommentCount int        `gorm:"not null;default:0" json:"comment_count"`
	CreatedAt    time.Time  `gorm:"not null;default:CURRENT_TIMESTAMP;index:idx_posts_created_at,sort:desc" json:"created_at"`
	UpdatedAt    time.Time  `gorm:"not null;default:CURRENT_TIMESTAMP" json:"updated_at"`
	DeletedAt    *time.Time `gorm:"index" json:"deleted_at,omitempty"`

	// Associations
	User     User        `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Media    []PostMedia `gorm:"foreignKey:PostID" json:"media,omitempty"`
	Comments []Comment   `gorm:"foreignKey:PostID" json:"comments,omitempty"`
	Likes    []Like      `gorm:"foreignKey:PostID" json:"likes,omitempty"`
	Hashtags []Hashtag   `gorm:"many2many:post_hashtags" json:"hashtags,omitempty"`
}

// TableName specifies the table name for Post model
func (Post) TableName() string {
	return "posts"
}

// PostMedia represents media files associated with a post
type PostMedia struct {
	ID           int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	PostID       int64     `gorm:"not null;index" json:"post_id"`
	MediaURL     string    `gorm:"size:500;not null" json:"media_url"`
	ThumbnailURL string    `gorm:"size:500" json:"thumbnail_url"`
	MediaType    string    `gorm:"size:20;not null" json:"media_type"`
	SortOrder    int       `gorm:"not null;default:0" json:"sort_order"`
	CreatedAt    time.Time `gorm:"not null;default:CURRENT_TIMESTAMP" json:"created_at"`

	// Associations
	Post Post `gorm:"foreignKey:PostID" json:"post,omitempty"`
}

// TableName specifies the table name for PostMedia model
func (PostMedia) TableName() string {
	return "post_media"
}

// Comment represents a user comment on a post
type Comment struct {
	ID        int64      `gorm:"primaryKey;autoIncrement" json:"id"`
	UserID    int64      `gorm:"not null;index" json:"user_id"`
	PostID    int64      `gorm:"not null;index" json:"post_id"`
	Content   string     `gorm:"type:text;not null" json:"content"`
	CreatedAt time.Time  `gorm:"not null;default:CURRENT_TIMESTAMP" json:"created_at"`
	DeletedAt *time.Time `gorm:"index" json:"deleted_at,omitempty"`

	// Associations
	User User `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Post Post `gorm:"foreignKey:PostID" json:"post,omitempty"`
}

// TableName specifies the table name for Comment model
func (Comment) TableName() string {
	return "comments"
}

// Like represents a user like on a post
type Like struct {
	ID        int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	UserID    int64     `gorm:"not null;uniqueIndex:idx_user_post" json:"user_id"`
	PostID    int64     `gorm:"not null;uniqueIndex:idx_user_post;index" json:"post_id"`
	CreatedAt time.Time `gorm:"not null;default:CURRENT_TIMESTAMP" json:"created_at"`

	// Associations
	User User `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Post Post `gorm:"foreignKey:PostID" json:"post,omitempty"`
}

// TableName specifies the table name for Like model
func (Like) TableName() string {
	return "likes"
}

// Hashtag represents a hashtag extracted from posts
type Hashtag struct {
	ID        int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	Name      string    `gorm:"uniqueIndex;size:100;not null" json:"name"`
	PostCount int       `gorm:"not null;default:0;index:idx_hashtags_post_count,sort:desc" json:"post_count"`
	CreatedAt time.Time `gorm:"not null;default:CURRENT_TIMESTAMP" json:"created_at"`

	// Associations
	Posts []Post `gorm:"many2many:post_hashtags" json:"posts,omitempty"`
}

// TableName specifies the table name for Hashtag model
func (Hashtag) TableName() string {
	return "hashtags"
}

// PostHashtag represents the many-to-many relationship between posts and hashtags
type PostHashtag struct {
	PostID    int64     `gorm:"primaryKey" json:"post_id"`
	HashtagID int64     `gorm:"primaryKey" json:"hashtag_id"`
	CreatedAt time.Time `gorm:"not null;default:CURRENT_TIMESTAMP" json:"created_at"`
}

// TableName specifies the table name for PostHashtag model
func (PostHashtag) TableName() string {
	return "post_hashtags"
}
