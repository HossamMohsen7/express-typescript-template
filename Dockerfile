# ---- Base image ----
FROM node:24-slim AS base
ENV PNPM_VERSION=10.28.2

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    openssl wget bash curl python3 python3-pip build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

#Uncomment if you use infisical
# RUN curl -1sLf 'https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.deb.sh' | bash \
#     && apt-get update && apt-get install -y infisical \
#     && apt-get clean \
#     && rm -rf /var/lib/apt/lists/*

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack disable \
    && curl -fsSL https://get.pnpm.io/install.sh | PNPM_VERSION=$PNPM_VERSION PNPM_HOME=$PNPM_HOME SHELL=/bin/bash bash - \
    && chown -R node:node $PNPM_HOME \
    && pnpm --version
WORKDIR /app
RUN chown node:node /app


# ---- Dependencies ----
FROM base AS deps
USER node
COPY --chown=node:node package.json pnpm-lock.yaml /app/
RUN --mount=type=cache,id=pnpm,target=/pnpm/store,uid=1000,gid=1000 pnpm install --prefer-offline --frozen-lockfile
ENV PATH=/app/node_modules/.bin:$PATH


# ---- Build ----
FROM base AS build
COPY --chown=node:node . /app
COPY --chown=node:node --from=deps /app/node_modules /app/node_modules
USER node
RUN pnpm run build


# ---- Source (for prod/dev split) ----
FROM base AS source
COPY --chown=node:node package.json pnpm-lock.yaml /app/
COPY --chown=node:node --from=build /app/dist /app/dist
COPY --chown=node:node --from=build /app/prisma /app/prisma
COPY --chown=node:node --from=deps /app/node_modules /app/node_modules
# Uncomment if you use something like Sentry
COPY --chown=node:node --from=build /app/src/instrument.mjs /app/instrument.mjs
USER node


# ---- Production ----
FROM source AS prod
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}
ENV PATH=/app/node_modules/.bin:$PATH
RUN pnpm prune --prod
#Uncomment if you use something like Sentry
# ENV NODE_OPTIONS="--import ./instrument.mjs"
CMD [ "pm2-runtime", "start", "dist/app.js" ]



# ---- Development ----
FROM source AS dev
ENV PATH=/app/node_modules/.bin:$PATH
ARG NODE_ENV=development
ENV NODE_ENV=${NODE_ENV}
CMD ["pnpm", "dev"]