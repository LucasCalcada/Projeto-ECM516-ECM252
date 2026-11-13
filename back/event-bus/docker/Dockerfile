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

COPY back/event-bus/ ./back/event-bus/
WORKDIR /app/back/event-bus
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
ENV NODE_ENV=production
WORKDIR /app

COPY --from=prod-dependencies --chown=node:node /app/node_modules ./node_modules
COPY --from=prod-dependencies --chown=node:node /app/package.json ./package.json

WORKDIR /app/back/event-bus
COPY --from=prod-dependencies --chown=node:node /app/back/event-bus/package.json ./package.json
COPY --from=builder --chown=node:node /app/back/event-bus/dist ./dist

USER node
EXPOSE 8004
CMD ["node", "dist/index.js"]
