# Build stage
FROM cirrusci/flutter:latest as build-stage

WORKDIR /app

# Copy Flutter app
COPY flutter_app/ /app/

# Get dependencies
RUN flutter pub get

# Build web
RUN flutter build web --release

# Production stage
FROM nginx:alpine

# Copy built app to nginx
COPY --from=build-stage /app/build/web /usr/share/nginx/html

# Copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
