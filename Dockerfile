################################################################################
## GO BUILDER
################################################################################
FROM golang:1.15.5 as builder

ENV VERSION 1.8.2
ENV BUILD_DIR /build

# Default (blank) will be for the underlying platform, typically "amd64"
# Can be over-ridden at build time, e.g. with "arm64"
ARG ARCH

RUN mkdir -p ${BUILD_DIR}
WORKDIR ${BUILD_DIR}

COPY go.* ./
RUN go mod download
COPY . .

RUN go test -cover ./...

# Must set GOARCH after running tests
ENV GOARCH=$ARCH

RUN CGO_ENABLED=0 go build -a -tags netgo -installsuffix netgo -ldflags "-X github.com/halverneus/static-file-server/cli/version.version=${VERSION}" -o /serve /build/bin/serve


RUN adduser --system --no-create-home --uid 1000 --shell /usr/sbin/nologin static

################################################################################
## DEPLOYMENT CONTAINER
################################################################################
FROM scratch

EXPOSE 8080
COPY --from=builder /serve /
COPY --from=builder /etc/passwd /etc/passwd

USER static
ENTRYPOINT ["/serve"]
CMD []

# Metadata
LABEL life.apets.vendor="Halverneus" \
    life.apets.url="https://github.com/halverneus/static-file-server" \
    life.apets.name="Static File Server" \
    life.apets.description="A tiny static file server" \
    life.apets.version="v1.8.2" \
    life.apets.schema-version="1.0"
