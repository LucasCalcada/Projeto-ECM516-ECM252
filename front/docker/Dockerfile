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

FROM dependencies AS build
COPY front/ ./front/
WORKDIR /app/front
ENV VITE_CORE_URL=/api/core \
    VITE_AUTH_URL=/api/auth \
    VITE_DELIVERY_URL=/api/delivery \
    VITE_VISITOR_URL=/api/visitor \
    VITE_RESERVATION_URL=/api/reservation \
    VITE_COMMUNICATION_URL=/api/communication
RUN yarn build

FROM nginx:1.28-alpine AS runtime
COPY front/docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/front/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
