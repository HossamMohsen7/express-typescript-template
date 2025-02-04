FROM node:22-slim AS base
ENV PNPM_VERSION=9.15.4
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN apt-get update -y && apt-get install -y openssl wget bash curl python3 build-essential
RUN curl -1sLf \
    'https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.deb.sh' | bash \
    && apt-get update && apt-get install -y infisical
RUN corepack enable && corepack use pnpm@${PNPM_VERSION}
WORKDIR /app
RUN chown node:node /app
RUN mkdir -p $PNPM_HOME && chown node:node $PNPM_HOME

FROM base AS deps
COPY --chown=node:node package*.json pnpm-lock.yaml /app/
RUN corepack enable && corepack use pnpm@${PNPM_VERSION}
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --prefer-offline --frozen-lockfile
ENV PATH /app/node_modules/.bin:$PATH

FROM base AS build
COPY --chown=node:node . /app
RUN corepack enable && corepack use pnpm@${PNPM_VERSION}
COPY --chown=node:node --from=deps /app/node_modules /app/node_modules
RUN pnpm run build

FROM base AS source
COPY --chown=node:node package*.json pnpm-lock.yaml /app/
COPY --chown=node:node --from=build /app/dist /app/dist
COPY --chown=node:node --from=build /app/prisma /app/prisma
COPY --chown=node:node --from=build /app/node_modules /app/node_modules

FROM source AS prod
RUN corepack enable && corepack use pnpm@${PNPM_VERSION}
RUN pnpm prune --prod
RUN pnpm add -g pm2
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}
CMD [ "pm2-runtime", "start", "dist/app.js", "-i", "max" ]

FROM source AS dev
ENV PATH /app/node_modules/.bin:$PATH
ARG NODE_ENV=development
ENV NODE_ENV=${NODE_ENV}
CMD ["pnpm", "dev"]