# Contributing

## Setup

```bash
npm ci
cp .env.example .env
npm test
npm run dev
```

## Workflow

- `main` — production-ready (PR + approval required)
- `develop` — integration branch
- `feature/*` — from `develop`
- `fix/*` — bug fixes

## Commits

Use [Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `infra:`, `docs:`, `ci:`, `test:`, `chore:`

## Before pushing

```bash
npm run lint
npm test
```
