# Use official Node.js runtime
FROM node:18-alpine

# Set working directory
WORKDIR /usr/src/app

# Copy source files
COPY app.js .

# Install dependencies (none needed for this minimal app)
RUN npm init -y && npm install express

# Expose port
EXPOSE 3000

# Start the app
CMD ["node", "app.js"]