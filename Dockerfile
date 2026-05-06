FROM node:22-alpine AS builder

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm ci --ignore-scripts

COPY src/ ./src/

FROM node:22-alpine AS production

LABEL org.opencontainers.image.title="cicd-pipeline" \
      org.opencontainers.image.description="CI/CD pipeline with Security gates" \
      org.opencontainers.image.source="https://github.com/tani-mani-meow/cicd-pipeline" \
      org.opencontainers.image.licenses="MIT"

ARG COMMIT_SHA=unknown
ARG BUILD_DATE=unknown

ENV NODE_ENV=production \
    COMMIT_SHA=${COMMIT_SHA} \
    BUILD_DATE=${BUILD_DATE} \
    PORT=3000

WORKDIR /app

COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/src ./src
COPY package.json ./

USER node

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["node", "src/server.js"]
