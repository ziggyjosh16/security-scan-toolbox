# Use the latest Alpine image as the base
FROM alpine:latest AS build
ENV SBOM_URL="https://amazon-inspector-sbomgen.s3.amazonaws.com/1.6.3/linux/amd64/inspector-sbomgen.zip"
ENV TRIVY_URL="https://github.com/aquasecurity/trivy/releases/download/v0.18.3/trivy_0.18.3_Linux-64bit.tar.gz"
ENV INSTALL_DIR="/usr/bin"
RUN apk update && apk add --no-cache bash zip curl
RUN curl -LO "$SBOM_URL" && \
    unzip inspector-sbomgen.zip && \
    mv ./inspector-sbomgen-1.6.3/linux/amd64/* . && \
    chmod +x inspector-sbomgen && \
    mv inspector-sbomgen "$INSTALL_DIR/"
RUN curl -LO "$TRIVY_URL" && \
    tar -xvf trivy_0.18.3_Linux-64bit.tar.gz && \
    chmod +x trivy && \
    mv trivy "$INSTALL_DIR/"
RUN mkdir -p /tmp


FROM golang:latest AS builder
WORKDIR /build
COPY ./dispatcher.go /build/
RUN CGO_ENABLED=0 GOOS=linux go build -o dispatcher dispatcher.go

    

FROM scratch
COPY --from=build /usr/bin/inspector-sbomgen usr/bin/inspector-sbomgen
COPY --from=build /usr/bin/trivy usr/bin/trivy
COPY --from=build /root/.cache/trivy /root/.cache/trivy
COPY --from=build /tmp /tmp
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /build/dispatcher /usr/bin/dispatcher
WORKDIR /project
ENTRYPOINT ["dispatcher"]
CMD ["--help"]