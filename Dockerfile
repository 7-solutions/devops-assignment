# syntax=docker/dockerfile:1
ARG GO_BUILDER_IMAGE=dhi.io/golang:1.26-dev
ARG RUNTIME_IMAGE=dhi.io/static:20230311
FROM ${GO_BUILDER_IMAGE} AS build

WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY main.go ./
RUN CGO_ENABLED=0 GOOS=linux go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /out/hello-api .

FROM ${RUNTIME_IMAGE} AS runtime

COPY --from=build --chown=65532:65532 /out/hello-api /hello-api
USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["/hello-api"]
