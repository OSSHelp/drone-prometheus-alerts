FROM prom/prometheus:v2.24.1 as prometheus
FROM alpine:3.10.5
# hadolint ignore=DL3018
RUN apk add --no-cache bash

COPY entrypoint.sh /usr/local/bin/
COPY --from=prometheus /bin/promtool /bin/

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
