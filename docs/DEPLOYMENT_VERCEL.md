# Website Deployment: GitHub → Vercel (Auto)

This guide deploys the Next.js website via Vercel, triggered automatically on GitHub pushes. The repo is a monorepo; we’ll point Vercel at the `website/` directory.

## 1) Push project to a public GitHub repo

From the project root (taiga/):

```bash
git init
git branch -M main
git add .
git commit -m "feat: initial import"
git remote add origin https://github.com/<your-username>/<your-repo>.git
git push -u origin main
```

Notes:
- Keep the monorepo structure intact (backend, website, pos, mobile, etc.).
- The website lives in `website/` and has a minimal `vercel.json` to help Vercel project detection.

## 2) Connect GitHub → Vercel

1. Create a Vercel account: https://vercel.com
2. Import Git Repository and install the Vercel GitHub App when prompted.
3. Select your repo.
4. In Project Settings → select:
   - Framework Preset: Next.js (auto-detected)
   - Root Directory: `website`
   - Install Command: `npm ci` (or `npm install`)
   - Build Command: `npm run build`
   - Output: auto (Next.js on Vercel)

## 3) Configure environment variables (if needed)

In Project Settings → Environment Variables, add any variables the website expects (API base URLs, keys, etc.). Set values for Production and Preview environments as needed.

## 4) Choose deploy behavior

- Production Branch: set to `master` (current default in this repo) or `main` if you rename later. Pushes/merges to the Production branch deploy to Production.
- Pull Requests: Vercel automatically creates Preview deployments per PR/branch.

## 5) Verify first deployment

After linking, Vercel will trigger the first build from `main`. You’ll get:
- A Production URL for `main`.
- Preview URLs on every PR.

## 6) Custom domain (optional)

In Vercel → Domains, add your domain and follow DNS steps. Point it to the Production deployment.

---

### Optional: GitHub Actions (Vercel CLI)

Vercel’s Git integration is recommended. If you prefer GitHub Actions, add this workflow and set repo secrets: `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID` (create the Vercel project first, then copy IDs from Settings → General).

```yaml
name: Vercel Deploy
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: website
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: website/package.json

      - name: Install deps
        run: npm ci

      - name: Pull Vercel env info
        run: npx vercel pull --yes --environment=${{ github.event_name == 'push' && 'production' || 'preview' }} --token=${{ secrets.VERCEL_TOKEN }}

      - name: Build
        run: npx vercel build --token=${{ secrets.VERCEL_TOKEN }}

      - name: Deploy
        run: npx vercel deploy --prebuilt --token=${{ secrets.VERCEL_TOKEN }} ${{ github.event_name == 'push' && '--prod' || '' }}
        env:
          VERCEL_ORG_ID: ${{ secrets.VERCEL_ORG_ID }}
          VERCEL_PROJECT_ID: ${{ secrets.VERCEL_PROJECT_ID }}
```

### Troubleshooting

- Ensure the Vercel project Root Directory is set to `website` (monorepo).
- If the build fails due to Node version, set `engines.node` in `website/package.json` (e.g., ">=18").
- Missing env vars will cause runtime/build errors—set them in Vercel.
- For images from external domains, configure `images.domains` in `next.config.ts`.
