FROM alpine:edge as builder
LABEL stage=go-builder
WORKDIR /app/
RUN apk add --no-cache bash curl gcc git go musl-dev
COPY go.mod go.sum ./
RUN go mod download
COPY ./ ./
RUN bash build.sh release docker

FROM alpine:edge

ARG INSTALL_FFMPEG=false
ARG INSTALL_ARIA2=false
LABEL MAINTAINER="i@nn.ci"

WORKDIR /opt/alist/

RUN apk update && \
    apk upgrade --no-cache && \
    apk add --no-cache bash ca-certificates su-exec tzdata; \
    [ "$INSTALL_FFMPEG" = "true" ] && apk add --no-cache ffmpeg; \
    [ "$INSTALL_ARIA2" = "true" ] && apk add --no-cache curl aria2 && \
        mkdir -p /root/.aria2 && \
        wget https://github.com/P3TERX/aria2.conf/archive/refs/heads/master.tar.gz -O /tmp/aria-conf.tar.gz && \
        tar -zxvf /tmp/aria-conf.tar.gz -C /root/.aria2 && rm -f /tmp/aria-conf.tar.gz && \
        sed -i 's|rpc-secret|#rpc-secret|g' /root/.aria2/aria2.conf && \
        touch /root/.aria2/aria2.session && \
        /root/.aria2/tracker.sh ; \
    rm -rf /var/cache/apk/*

COPY --from=builder /app/bin/alist ./
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /opt/alist/alist && \
    chmod +x /entrypoint.sh && /entrypoint.sh version

ENV PUID=0 PGID=0 UMASK=022 RUN_ARIA2=${INSTALL_ARIA2}
VOLUME /opt/alist/data/
EXPOSE 5244 5245
CMD [ "/entrypoint.sh" ]