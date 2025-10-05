# Dockerfile for a production Strapi application
# This uses a multi-stage build to create a small and secure final image.

# --- Build Stage ---
FROM node:20-alpine AS build
WORKDIR /opt/
RUN apk update && apk add --no-cache build-base gcc autoconf automake zlib-dev libpng-dev nasm bash vips-dev git

# Copy package files first to leverage Docker cache
COPY package.json yarn.lock* ./

# Install all dependencies
RUN yarn install --frozen-lockfile

# Copy the rest of the application source code
COPY . .

# Build the Strapi admin panel
RUN NODE_ENV=production yarn build

# --- Production Stage ---
FROM node:20-alpine
ENV NODE_ENV=production
WORKDIR /opt/app
RUN apk add --no-cache vips-dev

# Copy package files first to leverage Docker cache
COPY package.json yarn.lock* ./

# Install only production dependencies
RUN yarn install --production --frozen-lockfile

# Copy the built admin panel and required source files from the build stage
# Note: We copy the source code *after* installing dependencies
COPY --from=build /opt/build ./build
COPY . .

EXPOSE 1337
CMD ["yarn", "start"]

