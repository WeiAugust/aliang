# Contributing to Aliang

Thank you for your interest in contributing to Aliang! This document provides guidelines and instructions for contributing to the project.

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow
- Follow the project's coding standards

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/aliang.git
   cd aliang
   ```
3. **Set up the development environment** (see README.md)
4. **Create a new branch** for your feature or fix:
   ```bash
   git checkout -b feat/your-feature-name
   ```

## Branch Naming Convention

Use the following prefixes for branch names:

- `feat/` - New features
- `fix/` - Bug fixes
- `refactor/` - Code refactoring
- `docs/` - Documentation updates
- `test/` - Test additions or modifications
- `chore/` - Maintenance tasks

Examples:
- `feat/add-user-search`
- `fix/resolve-image-upload-timeout`
- `docs/update-api-documentation`

## Commit Message Format

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, missing semicolons, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples

```
feat(auth): add SMS verification code login

Implement SMS-based authentication with mock verification code
for development environment.

Closes #123
```

```
fix(upload): resolve image upload timeout issue

Increase upload timeout from 30s to 60s for large images.
Add retry logic for failed uploads.

Fixes #456
```

## Code Style

### Backend (Go)

- Follow standard Go conventions
- Use `gofmt` and `goimports` for formatting
- Run `go vet` before committing
- Use meaningful variable and function names
- Add comments for exported functions and types

```go
// Good
func CreatePost(ctx context.Context, req *CreatePostRequest) (*Post, error) {
    // Implementation
}

// Bad
func cp(c context.Context, r *CPR) (*P, error) {
    // Implementation
}
```

### Admin Panel (TypeScript/React)

- Follow the project's ESLint configuration
- Use TypeScript for type safety
- Use functional components with hooks
- Keep components small and focused
- Use meaningful component and variable names

```typescript
// Good
interface UserProfile {
  id: string
  nickname: string
  avatar: string
}

function UserProfileCard({ user }: { user: UserProfile }) {
  return <div>{user.nickname}</div>
}

// Bad
interface UP {
  i: string
  n: string
  a: string
}

function UPC({ u }: { u: UP }) {
  return <div>{u.n}</div>
}
```

## Testing Requirements

All contributions must include tests:

- **Backend**: Minimum 80% test coverage
  ```bash
  cd backend
  make test
  ```

- **Admin Panel**: Test critical functionality
  ```bash
  cd admin
  npm test
  ```

### Writing Tests

#### Backend (Go)

```go
func TestCreatePost(t *testing.T) {
    tests := []struct {
        name    string
        input   *CreatePostRequest
        want    *Post
        wantErr bool
    }{
        {
            name: "valid post",
            input: &CreatePostRequest{
                Title:   "Test Post",
                Content: "Test content",
            },
            want: &Post{
                Title:   "Test Post",
                Content: "Test content",
            },
            wantErr: false,
        },
        // Add more test cases
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := CreatePost(context.Background(), tt.input)
            if (err != nil) != tt.wantErr {
                t.Errorf("CreatePost() error = %v, wantErr %v", err, tt.wantErr)
                return
            }
            // Add assertions
        })
    }
}
```

#### Admin Panel (TypeScript)

```typescript
import { render, screen } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import UserProfileCard from './UserProfileCard'

describe('UserProfileCard', () => {
  it('renders user nickname', () => {
    const user = {
      id: '1',
      nickname: 'Test User',
      avatar: 'https://example.com/avatar.jpg',
    }

    render(<UserProfileCard user={user} />)
    expect(screen.getByText('Test User')).toBeInTheDocument()
  })
})
```

## Pull Request Process

1. **Update your branch** with the latest changes from main:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Run all tests** and ensure they pass:
   ```bash
   make test
   ```

3. **Run linters** and fix any issues:
   ```bash
   make lint
   ```

4. **Push your changes** to your fork:
   ```bash
   git push origin feat/your-feature-name
   ```

5. **Create a Pull Request** on GitHub with:
   - Clear title describing the change
   - Detailed description of what changed and why
   - Reference to related issues (e.g., "Closes #123")
   - Screenshots for UI changes

6. **Address review feedback** promptly and professionally

## Pull Request Checklist

Before submitting a PR, ensure:

- [ ] Code follows the project's style guidelines
- [ ] All tests pass (`make test`)
- [ ] Test coverage is maintained or improved (≥80%)
- [ ] Linters pass (`make lint`)
- [ ] Documentation is updated if needed
- [ ] Commit messages follow the conventional format
- [ ] No merge conflicts with main branch
- [ ] PR description clearly explains the changes

## Review Process

- All PRs require at least one approval from a maintainer
- Automated CI checks must pass
- Code coverage must not decrease
- Reviewers may request changes or ask questions
- Be patient and respectful during the review process

## Development Workflow

### Backend Development

```bash
# Start infrastructure services
docker-compose up -d

# Run migrations
cd backend
make migrate-up

# Start backend in development mode
make dev

# Run tests
make test

# Run linters
make lint
```

### Admin Panel Development

```bash
# Install dependencies
cd admin
npm install

# Start development server
npm run dev

# Run tests
npm test

# Run linters
npm run lint
```

## Common Issues

### Go Module Issues

If you encounter Go module issues:
```bash
cd backend
go mod tidy
go mod download
```

### Node Module Issues

If you encounter npm issues:
```bash
cd admin
rm -rf node_modules package-lock.json
npm install
```

### Database Migration Issues

If migrations fail:
```bash
cd backend
make migrate-down  # Rollback
make migrate-up    # Reapply
```

## Getting Help

- Check existing issues on GitHub
- Read the documentation in the `docs/` directory
- Ask questions in GitHub Discussions
- Contact maintainers via GitHub issues

## License

By contributing to Aliang, you agree that your contributions will be licensed under the MIT License.
