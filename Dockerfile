FROM prom/prometheus:v2.24.1 as prometheus
FROM mikefarah/yq:3 as yq

FROM alpine:3.13
# hadolint ignore=DL3018
RUN apk add --no-cache bash

COPY entrypoint.sh /usr/local/bin/
COPY --from=prometheus /bin/promtool /bin/
COPY --from=prometheus /etc/prometheus/prometheus.yml /etc/prometheus/prometheus.yml
COPY --from=yq /usr/bin/yq /bin/

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
