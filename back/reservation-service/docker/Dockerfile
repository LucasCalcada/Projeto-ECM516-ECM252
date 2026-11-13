# Stage 1: Build stage
FROM node:22-alpine AS builder
WORKDIR /app

COPY package.json yarn.lock ./
COPY front/package.json ./front/package.json
COPY back/auth-service/package.json ./back/auth-service/package.json
COPY back/core-service/package.json ./back/core-service/package.json
COPY back/delivery-service/package.json ./back/delivery-service/package.json
COPY back/visitor-service/package.json ./back/visitor-service/package.json
COPY back/reservation-service/package.json ./back/reservation-service/package.json
COPY back/communication-service/package.json ./back/communication-service/package.json
COPY back/event-bus/package.json ./back/event-bus/package.json
RUN yarn install --frozen-lockfile --non-interactive

COPY back/reservation-service/ ./back/reservation-service/
WORKDIR /app/back/reservation-service
RUN yarn build

# Stage 2: Production dependencies
FROM node:22-alpine AS prod-dependencies
WORKDIR /app

COPY package.json yarn.lock ./
COPY front/package.json ./front/package.json
COPY back/auth-service/package.json ./back/auth-service/package.json
COPY back/core-service/package.json ./back/core-service/package.json
COPY back/delivery-service/package.json ./back/delivery-service/package.json
COPY back/visitor-service/package.json ./back/visitor-service/package.json
COPY back/reservation-service/package.json ./back/reservation-service/package.json
COPY back/communication-service/package.json ./back/communication-service/package.json
COPY back/event-bus/package.json ./back/event-bus/package.json
RUN yarn install --frozen-lockfile --production --non-interactive \
    && yarn cache clean

# Stage 3: Runtime
FROM node:22-alpine AS runtime
ENV NODE_ENV=production \
    POPULATE_DB=false
WORKDIR /app

COPY --from=prod-dependencies --chown=node:node /app/node_modules ./node_modules
COPY --from=prod-dependencies --chown=node:node /app/package.json ./package.json

WORKDIR /app/back/reservation-service
COPY --from=prod-dependencies --chown=node:node /app/back/reservation-service/package.json ./package.json
COPY --from=builder --chown=node:node /app/back/reservation-service/dist ./dist
COPY --chown=node:node back/reservation-service/drizzle.config.ts ./drizzle.config.ts
COPY --chown=node:node back/reservation-service/drizzle.k8s.config.ts ./drizzle.k8s.config.ts
COPY --chown=node:node back/reservation-service/tsconfig.json ./tsconfig.json
COPY --chown=node:node back/reservation-service/src/ ./src/
COPY --chown=node:node back/reservation-service/migrations/ ./migrations/

USER node
EXPOSE 8005
CMD ["sh", "-c", "yarn drizzle-kit push && if [ \"$POPULATE_DB\" = \"true\" ] || [ \"$POPULATE_DB\" = \"1\" ]; then [ -f \"dist/scripts/populate.js\" ] && node dist/scripts/populate.js; fi && exec node dist/index.js"]
