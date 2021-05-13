FROM --platform=$BUILDPLATFORM golang:1.16-alpine AS builder-src

ARG version="v0.18.1"
WORKDIR /opt

RUN apk add -U git
RUN git clone https://github.com/operator-framework/operator-lifecycle-manager
WORKDIR /opt/operator-lifecycle-manager
RUN git checkout ${version}



FROM builder-src AS builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM

RUN GOOS=$(echo $TARGETPLATFORM | cut -f1 -d/) && \
    GOARCH=$(echo $TARGETPLATFORM | cut -f2 -d/) && \
    GOARM=$(echo $TARGETPLATFORM | cut -f3 -d/ | sed "s/v//" ) && \
    CGO_ENABLED=0 GOOS=${GOOS} GOARCH=${GOARCH} GOARM=${GOARM} go build -v -mod=vendor -tags "json1" ./cmd/olm

RUN GOOS=$(echo $TARGETPLATFORM | cut -f1 -d/) && \
    GOARCH=$(echo $TARGETPLATFORM | cut -f2 -d/) && \
    GOARM=$(echo $TARGETPLATFORM | cut -f3 -d/ | sed "s/v//" ) && \
    CGO_ENABLED=0 GOOS=${GOOS} GOARCH=${GOARCH} GOARM=${GOARM} go build -v -mod=vendor -tags "json1"  ./cmd/catalog

RUN GOOS=$(echo $TARGETPLATFORM | cut -f1 -d/) && \
    GOARCH=$(echo $TARGETPLATFORM | cut -f2 -d/) && \
    GOARM=$(echo $TARGETPLATFORM | cut -f3 -d/ | sed "s/v//" ) && \
    CGO_ENABLED=0 GOOS=${GOOS} GOARCH=${GOARCH} GOARM=${GOARM} go build -v -mod=vendor -tags "json1"  ./cmd/package-server


RUN GOOS=$(echo $TARGETPLATFORM | cut -f1 -d/) && \
    GOARCH=$(echo $TARGETPLATFORM | cut -f2 -d/) && \
    GOARM=$(echo $TARGETPLATFORM | cut -f3 -d/ | sed "s/v//" ) && \
    CGO_ENABLED=0 GOOS=${GOOS} GOARCH=${GOARCH} GOARM=${GOARM} go build -v -mod=vendor -ldflags '-extldflags "-static"' -o cpb ./util/cpb




FROM gcr.io/distroless/static

COPY --from=builder /opt/operator-lifecycle-manager/olm /bin/olm
COPY --from=builder /opt/operator-lifecycle-manager/catalog /bin/catalog
COPY --from=builder /opt/operator-lifecycle-manager/package-server /bin/package-server
COPY --from=builder /opt/operator-lifecycle-manager/cpb /bin/cpb

USER 1234

ENTRYPOINT ["/bin/olm"]

