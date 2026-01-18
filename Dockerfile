# Base stage
FROM node:20.10.0-alpine AS base
WORKDIR /app

# Development stage
FROM base AS development
COPY package*.json ./
RUN npm ci
COPY . .
ENV NODE_ENV=development
EXPOSE 3000
CMD ["npm", "run", "dev"]

# Builder stage
FROM base AS builder
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

# Production stage
FROM base AS production
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package*.json ./
ENV NODE_ENV=production
EXPOSE 3000
CMD ["node", "dist/index.js"]
