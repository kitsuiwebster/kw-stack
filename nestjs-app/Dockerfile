# Stage 1: Build the application
FROM node:18 AS build

# Set the working directory
WORKDIR /app

# Copy the package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application
COPY . .

# Build the NestJS app
RUN npm run build

# Stage 2: Serve the application
FROM node:18

# Set the working directory
WORKDIR /app

# Copy the built application from the build stage
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package*.json ./

# Expose the port the app runs on
EXPOSE 3000

# Start the application
CMD ["node", "dist/main.js"]
