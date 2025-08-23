# -----------------------
# 1. Build Stage
# -----------------------
FROM golang:1.21.4-alpine AS builder

# Install git & certificates (needed for any dependencies)
RUN apk add --no-cache git ca-certificates

# Set working directory
WORKDIR /app

# Copy go.mod first to cache dependencies
COPY go.mod ./
RUN go mod download

# Copy the rest of the files
COPY . .

# Build the Go binary (disable CGO for static binary)
RUN CGO_ENABLED=0 GOOS=linux go build -o app main.go

# -----------------------
# 2. Run Stage
# -----------------------
FROM alpine:latest

# Create non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy the compiled binary
COPY --from=builder /app/app .

# Use non-root user
USER appuser

# Expose port (adjust if your app uses a different port)
EXPOSE 8080

# Start the application
ENTRYPOINT ["./app"]
