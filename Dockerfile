FROM node:20-slim AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

RUN apt-get update -y && apt-get install -y openssl
RUN apt-get update && apt-get install -y wget

RUN corepack enable
WORKDIR /app
RUN chown node:node /app
RUN mkdir $PNPM_HOME && chown node:node $PNPM_HOME
USER node

FROM base AS deps
USER root
COPY --chown=node:node package*.json pnpm-lock.yaml /app/
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --prefer-offline --frozen-lockfile
ENV PATH /app/node_modules/.bin:$PATH

FROM base AS build
COPY --chown=node:node . /app
COPY --chown=node:node --from=deps /app/node_modules /app/node_modules
RUN pnpm run build

FROM base AS source
COPY --chown=node:node package*.json pnpm-lock.yaml /app/
COPY --chown=node:node --from=build /app/dist /app/dist
COPY --chown=node:node --from=build /app/prisma /app/prisma
COPY --chown=node:node --from=build /app/node_modules /app/node_modules

FROM source AS prod
RUN pnpm prune --prod
RUN pnpm add -g pm2

ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}

FROM source AS dev
ARG NODE_ENV=development
ENV NODE_ENV=${NODE_ENV}
