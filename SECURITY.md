# Security Policy

## Reporting a Vulnerability

Open a GitHub Issue. Do not email.

## Measures

- OIDC authentication (no stored AWS keys)
- Trivy + Hadolint scanning on every build
- ECR scan-on-push (double scanning)
- Non-root container (`node` user)
- Multi-stage build, Alpine base
- Private subnets for ECS tasks
- Helmet.js security headers
- Input size limits (10KB)
- SHA-pinned GitHub Actions
