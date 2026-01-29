FROM alpine AS builder
ARG SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH:-0}
RUN apk add --no-cache ca-certificates build-base make gcc autoconf libsodium-dev libsodium-static git go

FROM builder AS source-mkp
ARG SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH:-0}
WORKDIR /root
ADD https://github.com/cathugger/mkp224o.git mkp224o

FROM builder AS source-lyrebird
ARG SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH:-0}
WORKDIR /root
ADD https://github.com/Gharib110/lyrebird.git lyrebird

FROM source-mkp AS build-mkp
ARG SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH:-0}
WORKDIR /root/mkp224o
RUN ./autogen.sh && ./configure --enable-amd64-51-30k LDFLAGS=-static && make && cp mkp224o /

FROM source-lyrebird AS build-lyrebird
ARG SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH:-0}
WORKDIR /root/lyrebird
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-buildid= -s -w -X 'main.lyrebirdVersion=`git describe`'" ./cmd/lyrebird && cp lyrebird /

FROM alpine AS runner
ARG SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH:-0}
RUN apk add --no-cache ca-certificates curl make libsodium tor
RUN rm -rf /etc/tor/torrc.sample /var/log/tor && chown -R tor:nogroup /var/lib/tor && chmod 700 /var/lib/tor

FROM scratch AS build
ARG SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH:-0}
COPY --from=runner / /
COPY --from=build-mkp /mkp224o /usr/bin/
COPY --from=build-lyrebird /lyrebird /usr/bin/
COPY .curlrc /root/
COPY testdata /testdata
COPY test.mk /
COPY --chmod=755 docker-entrypoint.sh /
COPY --chmod=755 keygen /usr/bin/

FROM scratch
ARG SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH:-0}
COPY --from=build / /

HEALTHCHECK --start-period=30s --start-interval=3s --retries=10 --timeout=10s --interval=30s \
	CMD test -n "$RELAY" || curl https://check.torproject.org/api/ip || exit 1

EXPOSE 9050 9051 9053
ENTRYPOINT ["/docker-entrypoint.sh"]
