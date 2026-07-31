FROM node:24-slim

# Enable pnpm via corepack. Pin the version so image builds are reproducible.
RUN corepack enable && corepack prepare pnpm@11.17.0 --activate

WORKDIR /app

# Install dependencies (layer cached).
# pnpm-workspace.yaml carries the install settings (onlyBuiltDependencies,
# allowBuilds) that pnpm 10+ no longer reads from package.json — without it
# @sentry/cli's postinstall is silently skipped and its binary never lands.
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
RUN pnpm install --frozen-lockfile

# Copy the rest of the source. This image is meant to be self-contained
# (no bind-mount of the source tree at runtime), unlike the original
# dev-compose workflow this Dockerfile was written for.
COPY . .

# PUBLIC_-prefixed vars are inlined into the client bundle at build time by
# Vite, so this must be available before `pnpm build`, not just at runtime.
ARG PUBLIC_DJANGO_API_URL
ENV PUBLIC_DJANGO_API_URL=$PUBLIC_DJANGO_API_URL

RUN pnpm build

EXPOSE 5173
ENV PORT=5173
ENV HOST=0.0.0.0

CMD ["node", "build/index.js"]
