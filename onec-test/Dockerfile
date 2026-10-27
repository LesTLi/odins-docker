# syntax=docker/dockerfile:1.7
ARG BASE_IMAGE=ubuntu:22.04
ARG DIST_SOURCE=local
FROM ${BASE_IMAGE} AS downloader
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
COPY scripts/ /build/scripts/
COPY versions.env /build/versions.env
RUN apt-get update && apt-get install -y --no-install-recommends python3 unzip p7zip-full \
    && bash /build/scripts/install-tools.sh downloader \
    && rm -rf /var/lib/apt/lists/*
ARG ONEC_VERSION=8.3.27.2130
ARG INSTALL_FORMAT=deb
RUN --mount=type=secret,id=onec_username,required=true \
    --mount=type=secret,id=onec_password,required=true \
    bash /build/scripts/acquire.sh download "$INSTALL_FORMAT" onec-test "$ONEC_VERSION" /unused /distribution

FROM ${BASE_IMAGE} AS local
COPY scripts/ /build/scripts/
RUN apt-get update && apt-get install -y --no-install-recommends python3 ca-certificates \
    && rm -rf /var/lib/apt/lists/*
ARG ONEC_VERSION=8.3.27.2130
ARG INSTALL_FORMAT=deb
RUN --mount=type=bind,source=distr,target=/input \
    bash /build/scripts/acquire.sh local "$INSTALL_FORMAT" onec-test "$ONEC_VERSION" /input /distribution

FROM downloader AS source-download
FROM local AS source-local
FROM source-${DIST_SOURCE} AS distribution
FROM scratch AS distribution-export
COPY --from=distribution /distribution/ /

FROM ${BASE_IMAGE} AS tools
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
COPY scripts/ /build/scripts/
COPY versions.env /build/versions.env
RUN bash /build/scripts/install-deps.sh ui && bash /build/scripts/install-tools.sh test \
    && groupadd --gid 10001 onec \
    && useradd --uid 10001 --gid 10001 --create-home --shell /bin/bash onec \
    && mkdir /workspace && chown onec:onec /workspace
COPY --chmod=755 scripts/entrypoint.sh /usr/local/bin/onec-entrypoint
COPY --chmod=755 scripts/configure-runtime.sh /usr/local/bin/configure-onec-runtime
COPY --chmod=755 scripts/test-entrypoint.sh /usr/local/bin/test-entrypoint
COPY --chmod=755 scripts/nircmd /usr/local/bin/nircmd
ENV LANG=ru_RU.UTF-8 LC_ALL=ru_RU.UTF-8 TZ=Asia/Novosibirsk \
    HOME=/home/onec ONEC_IMAGE=onec-test
WORKDIR /workspace
ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/usr/local/bin/onec-entrypoint"]
USER 10001:10001
CMD ["bash"]

FROM tools AS runtime
USER root
ARG IMAGE_VERSION=1.0
ARG ONEC_VERSION=8.3.27.2130
ARG INSTALL_FORMAT=deb
RUN --mount=type=bind,from=distribution,source=/distribution,target=/distribution \
    bash /build/scripts/install-platform.sh "$INSTALL_FORMAT" onec-test "$ONEC_VERSION" /distribution \
    && rm -rf /build
LABEL org.opencontainers.image.title="odins-docker onec-test" \
      org.opencontainers.image.version=${IMAGE_VERSION} \
      io.github.lestli.odins-docker.onec.version=${ONEC_VERSION} \
      io.github.lestli.odins-docker.install.format=${INSTALL_FORMAT}
USER 10001:10001
CMD ["bash"]
