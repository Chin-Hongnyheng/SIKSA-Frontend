# Step 1: Build Stage
FROM cirrusci/flutter:stable AS build
WORKDIR /app

# 1. Copy dependencies first to cache them
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# 2. Copy the rest of the source and build
COPY . .
RUN flutter build web --release

# Step 2: Production Stage
FROM nginx:alpine

# 3. Copy a custom Nginx config (Highly Recommended)
# If you don't have a custom config, see the note below.
# COPY nginx.conf /etc/nginx/conf.d/default.conf

# 4. Copy the build output
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]