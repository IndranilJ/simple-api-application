# Multi-stage build for React frontend
# Stage 1: Build the React app
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package.json package-lock.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Accept backend URL as a build argument
ARG VITE_API_URL=http://localhost:8004
# Make it available as an environment variable for Vite during build
ENV VITE_API_URL=$VITE_API_URL

# Build the production bundle (Vite bakes VITE_* env vars into the JS output)
RUN npm run build

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Copy built assets from builder
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
