# Repository Guidelines

## Project Structure & Module Organization
- `backend/` contains the Go API (`cmd/api` entrypoint, `internal/{handler,service,repository,...}` business logic, `migrations/` SQL schema changes).
- `admin/` contains the React + TypeScript admin app (`src/` for app code, `index.html` + Vite config at root).
- `docs/` stores API specs and architecture/deployment notes; `docker-compose.yml` provisions PostgreSQL, Redis, and MinIO for local dev.
- Root scripts like `start.sh` and `test_upload.sh` support local setup and media upload verification.

## Build, Test, and Development Commands
- `make dev` (root): starts infrastructure containers only.
- `cd backend && make dev`: runs backend API on `:8080` (auto-creates `.env` from `.env.example` if missing).
- `cd admin && npm run dev`: starts Vite dev server on `:3000`.
- `make test`: runs backend race+coverage tests and admin tests.
- `make lint`: runs `go vet`, `staticcheck`, and admin ESLint checks.
- `make migrate-up` / `make migrate-down`: apply or roll back DB migrations.

## Coding Style & Naming Conventions
- **Go**: follow `gofmt` formatting and idiomatic naming (`UploadHandler`, `NewUploadHandler`); keep packages lowercase and focused by layer.
- **TypeScript/React**: strict TypeScript, functional components, PascalCase component files (e.g., `AdminLayout.tsx`), and route/page folders like `pages/Posts/index.tsx`.
- Use descriptive branch names from `CONTRIBUTING.md`, e.g., `feat/add-user-search`, `fix/upload-timeout`.

## Testing Guidelines
- Backend tests use Go’s `testing` package (plus `testify` where useful) and should live beside implementation files as `*_test.go`.
- Admin tests run with Vitest; add `*.test.tsx`/`*.spec.tsx` near components/pages when adding UI logic.
- Keep or improve backend coverage (target: **≥80%** per `CONTRIBUTING.md`) and run `make test` before opening a PR.

## Commit & Pull Request Guidelines
- Git history follows Conventional Commits (`feat: ...`, `docs: ...`, `fix: ...`); use imperative, concise subjects and optional scopes (e.g., `feat(auth): add token refresh`).
- Before PR: rebase on `main`, run `make test` and `make lint`, and update docs/migrations when behavior changes.
- PRs should include a clear summary, linked issue (`Closes #123`), and screenshots for admin UI changes.

## Security & Configuration Tips
- Never commit secrets; copy from `.env.example` and keep local overrides untracked.
- Treat migration files as immutable once merged; add a new numbered migration for schema changes.
