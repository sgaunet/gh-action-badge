FROM sgaunet/gobadger:0.3.1 AS gobadger

FROM alpine:3.22.2

RUN apk add --no-cache bash curl jq git
COPY --from=gobadger /usr/bin/gobadger /usr/bin/gobadger

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
