# Dockerfile for a production Strapi application
# This uses a multi-stage build to create a small and secure final image.

# --- Build Stage ---
# This stage installs all dependencies, including devDependencies,
# and builds the Strapi admin panel.
FROM node:20-alpine AS build

# Set the working directory
WORKDIR /opt/

# Install dependencies required for 'sharp' (a Strapi dependency)
RUN apk update && apk add --no-cache build-base gcc autoconf automake zlib-dev libpng-dev nasm bash vips-dev git

# Copy package.json and yarn.lock
COPY package.json yarn.lock* ./

# Install all dependencies
RUN yarn install --frozen-lockfile

# Copy the rest of the application source code
COPY . .

# Build the Strapi admin panel
# The NODE_ENV is set to production to ensure the build is optimized.
RUN NODE_ENV=production yarn build

# --- Production Stage ---
# This stage creates the final, lean image that will run the application.
FROM node:20-alpine

# Set environment to production
ENV NODE_ENV=production

# Set the working directory
WORKDIR /opt/app

# Install only the runtime dependencies for 'sharp'
RUN apk add --no-cache vips-dev

# Copy package.json and yarn.lock
COPY package.json yarn.lock* ./

# Install only production dependencies
RUN yarn install --production --frozen-lockfile

# Copy the built admin panel and required source files from the build stage
COPY --from=build /opt/build ./build
COPY --from=build /opt/config ./config
COPY --from=build /opt/database ./database
COPY --from=build /opt/src ./src
COPY --from=build /opt/public ./public

# Expose the default Strapi port
EXPOSE 1337

# Start the Strapi application
CMD ["yarn", "start"]
