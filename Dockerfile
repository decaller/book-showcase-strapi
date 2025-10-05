# Dockerfile for a production Strapi application
# This uses a multi-stage build to create a small and secure final image.

# --- Build Stage ---
# This stage installs all dependencies, including devDependencies,
# and builds the Strapi admin panel.
FROM node:20-alpine AS build
WORKDIR /opt/
RUN apk update && apk add --no-cache build-base gcc autoconf automake zlib-dev libpng-dev nasm bash vips-dev git

# Copy package files first to leverage Docker cache
COPY package.json yarn.lock* ./

# Install all dependencies
RUN yarn install --frozen-lockfile

# Copy the rest of the application source code
COPY . .

# Build the Strapi admin panel. This creates the /opt/build directory.
RUN NODE_ENV=production yarn build

# --- Production Stage ---
# This stage creates the final, lean image that will run the application.
FROM node:20-alpine
ENV NODE_ENV=production
WORKDIR /opt/app

# Install only the runtime dependencies for 'sharp'
RUN apk add --no-cache vips-dev

# Copy package files from the build stage to leverage cache
COPY --from=build /opt/package.json /opt/yarn.lock* ./

# Install only production dependencies.
RUN yarn install --production --frozen-lockfile

# Copy the built admin panel from the build stage
COPY --from=build /opt/build ./build

# Copy the necessary source code from the build stage
COPY --from=build /opt/config ./config
COPY --from=build /opt/database ./database
COPY --from=build /opt/src ./src
COPY --from=build /opt/public ./public

EXPOSE 1337
CMD ["yarn", "start"]

