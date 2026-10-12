FROM node:22-bookworm-slim AS dependencies
WORKDIR /app

# Install from the monorepo lockfile and preserve Yarn's workspace dependency layout.
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

FROM dependencies AS runtime
ENV NODE_ENV=production
WORKDIR /app/back/core-service
COPY --chown=node:node back/core-service/ ./
USER node
EXPOSE 8000
# Synchronize the local development schema without running destructive sample-data seeds.
CMD ["sh", "-c", "yarn drizzle-kit push && exec node --import tsx src/index.ts"]
