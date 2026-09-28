FROM ghcr.io/sgaunet/gobadger:0.5.0 AS gobadger

FROM alpine:3.24.2

RUN apk add --no-cache bash curl jq git bc
COPY --from=gobadger /usr/bin/gobadger /usr/bin/gobadger

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
