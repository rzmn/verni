# Dockerfile References: https://docs.docker.com/engine/reference/builder/

# Start from the latest golang base image
FROM golang:latest
RUN go version

ENV GIN_MODE release
ENV CONFIG_PATH "./config/dev.yaml"
ENV GOPATH=/

# Add files to app folder
COPY ./ ./

RUN go mod download
# Build the Go app
RUN go build -o main ./cmd/accounty/main.go

# Expose ports to the outside world
EXPOSE 8082

RUN mkdir -p ./data && chmod a+rwx -R ./data

# Command to run the executable
CMD ["./main"]
