# RAHATI API Backend — production container image.
#
# Alpha-environment scoped (docs/deployment/alpha-environment.md): this
# builds a deployable image, it does not itself deploy anywhere. Multi-stage
# so the runtime image ships only compiled output + production
# dependencies, never source/dev tooling.
#
# node:22-slim (Debian), not -alpine: Prisma's engine binaries have
# well-documented OpenSSL/musl issues on Alpine; -slim avoids that class of
# problem entirely. Matches this project's @types/node ^22.9.0.
#
# Prisma's generator has no `binaryTargets` override (schema.prisma), so the
# client's query-engine binary is resolved against whatever OS `prisma
# generate` runs on — it MUST run inside this build (build stage below), not
# be copied in from a host machine, or the runtime stage will get a binary
# for the wrong platform.

FROM node:22-slim AS build
WORKDIR /app

# Dependency manifests first for Docker layer caching — this layer is only
# invalidated when package*.json actually changes, not on every source edit.
COPY package.json package-lock.json ./
RUN npm ci

# Prisma needs its schema present to generate the client.
COPY prisma ./prisma
RUN npx prisma generate

# Remaining source, then compile.
COPY tsconfig.json tsconfig.build.json nest-cli.json ./
COPY src ./src
RUN npm run build

# ---

FROM node:22-slim AS runtime
WORKDIR /app
ENV NODE_ENV=production

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# The generated Prisma client (build stage's `prisma generate` output lives
# under node_modules/@prisma/client and node_modules/.prisma) is NOT
# reproduced by the production-only `npm ci` above, so it's copied forward
# explicitly rather than re-generated here.
COPY --from=build /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=build /app/node_modules/@prisma ./node_modules/@prisma
COPY --from=build /app/prisma ./prisma
COPY --from=build /app/dist ./dist

# api-architecture.md's global prefix excludes /health; main.ts binds
# `config.port` (PORT env var, defaults per configuration.ts) — the platform
# assigns/reads this port for its own routing, no fixed EXPOSE value implied.
EXPOSE 3000

CMD ["node", "dist/main.js"]
