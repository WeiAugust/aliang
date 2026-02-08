# Vercel Deployment Configuration

This document describes how to set up automatic deployment of the admin panel to Vercel.

## Prerequisites

1. **Vercel Account**: Sign up at https://vercel.com
2. **Vercel CLI** (optional, for local testing):
   ```bash
   npm i -g vercel
   ```

## Setup Steps

### 1. Create Vercel Project

**Option A: Via Vercel Dashboard**
1. Go to https://vercel.com/new
2. Import your GitHub repository
3. Configure the project:
   - **Framework Preset**: Vite
   - **Root Directory**: `admin`
   - **Build Command**: `npm run build`
   - **Output Directory**: `dist`
4. Add environment variables:
   - `VITE_API_URL`: Your backend API URL (e.g., `https://your-api.domain.com`)
5. Deploy

**Option B: Via CLI**
```bash
cd admin
vercel
```

### 2. Get Configuration Values

After creating the project, get the values for GitHub Actions:

```bash
# Get Organization ID and Project ID
vercel inspect --local false
```

Or via Vercel Dashboard:
1. Go to Project Settings → General
2. Copy **Project ID**
3. Go to Account Settings → General
4. Copy **Team/Organization ID** (or use personal/org ID)

### 3. Configure GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions:

**Required Secrets:**
| Name | Value |
|------|-------|
| `VERCEL_TOKEN` | Your Vercel access token (https://vercel.com/tokens) |
| `VERCEL_ORG_ID` | Your Vercel Organization ID |
| `VERCEL_PROJECT_ID` | Your Vercel Project ID |

**Required Variables:**
| Name | Value |
|------|-------|
| `VITE_API_URL` | Backend API URL for production |

### 4. Trigger Deployment

Push to main branch or create a pull request:
```bash
git add .github/workflows/admin-deploy.yml
git commit -m "feat: add vercel deploy workflow"
git push origin main
```

## Deployment URLs

- **Production**: `https://<your-project>.vercel.app`
- **Preview**: Available for each PR

## Environment Variables

Configure these in Vercel Dashboard → Project → Settings → Environment Variables:

| Variable | Value | Environment |
|----------|-------|-------------|
| `VITE_API_URL` | Backend API URL | Production, Preview, Development |

## Updating Deployment

The workflow automatically deploys when:
- Push to `main` branch with changes in `admin/**`
- Pull requests targeting `main` with changes in `admin/**`

## Rollback

To rollback:
1. Go to Vercel Dashboard → Deployments
2. Select a previous deployment
3. Click "Deploy" to promote it to production
