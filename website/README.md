This is a [Next.js](https://nextjs.org) project bootstrapped with [`create-next-app`](https://nextjs.org/docs/app/api-reference/cli/create-next-app).

## Getting Started

First, run the development server:

```bash
npm run dev
# or
yarn dev
# or
pnpm dev
# or
bun dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.

You can start editing the page by modifying `app/page.tsx`. The page auto-updates as you edit the file.

This project uses [`next/font`](https://nextjs.org/docs/app/building-your-application/optimizing/fonts) to automatically optimize and load [Geist](https://vercel.com/font), a new font family for Vercel.

## Learn More

To learn more about Next.js, take a look at the following resources:

- [Next.js Documentation](https://nextjs.org/docs) - learn about Next.js features and API.
- [Learn Next.js](https://nextjs.org/learn) - an interactive Next.js tutorial.

You can check out [the Next.js GitHub repository](https://github.com/vercel/next.js) - your feedback and contributions are welcome!

## Deploy on Vercel

Recommended: Deploy via Vercel (monorepo)

- Project Root: set to `website`
- Build Command: `npm run build`
- Output: Next.js (default)
- Environment variables (Production & Preview):
	- `NEXT_PUBLIC_SITE_URL` = your frontend domain (e.g., `https://www.taiga.asia`)
	- `NEXT_PUBLIC_API_URL` = your API base (e.g., `https://taiga.asia/api`)

GitHub Actions (auto-deploy)

- This repo includes a workflow at `.github/workflows/deploy-website-vercel.yml` that:
	- Deploys Preview on pull requests touching `website/`
	- Deploys Production on pushes to `main` touching `website/`
- Required GitHub Secrets:
	- `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`

Verify after deploy

- Homepage loads and links work
- Product pages list from API and paginate
- Network requests target `NEXT_PUBLIC_API_URL`
- Health endpoint responds: `/api/health`

Learn more in the official docs: [Next.js deployment](https://nextjs.org/docs/app/building-your-application/deploying)
