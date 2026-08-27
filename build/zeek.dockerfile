# Builder image reference: https://github.com/zeek/zeek/blob/master/docker/builder.Dockerfile
FROM debian:trixie-slim as builder

# Make the shell split commands in the log so we can determine reasons for
# failures more easily.
SHELL ["/bin/sh", "-x", "-c"]

# Directory to build zeek
ENV WD=/scratch

# Version variable. It can be specified when building image with --build-arg otherwise it will use 6.0.4 as default value
ARG VER=8.0.10

# Type of Zeek to build (Production ready or Debug)
ARG BUILD_TYPE=Release

# GEOIP variable. If set to true when building image, it will copy maxmind db to correct directory. Otherwise database won't be copied
ARG GEOIP=false

# If directory does not exits, it will be automatically created
WORKDIR ${WD}

# Install necessary dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    # Not 100% sure needed but it is required according to zeek's documentation and very light (bind9)
    bind9 \
    bison \
    # Useful to curl against zeek's site (ca-certificates)
    ca-certificates \
    cmake  \
    # From Zeek 8, by default, compilation and execution depend on the availability of the ZeroMQ library, this is in preparation of switching to the ZeroMQ-based cluster backend; this package is therefore required
    cppzmq-dev \
    curl \
    flex \
    g++ \
    gcc \
    git \
    libfl2 \
    libfl-dev \
    # Needed only if using GEOIP (but very light so not conditionally included) (libmaxminddb-dev)
    libmaxminddb-dev \
    libpcap-dev \
    libssl-dev \
    # Not sure why needed but very light (libuv1-dev)
    libuv1-dev \  
    libz-dev \
    # From Zeek 8, by default, compilation and execution depend on the availability of the ZeroMQ library, this is in preparation of switching to the ZeroMQ-based cluster backend; these two packages are therefore required
    libzmq5 \
    libzmq3-dev \
    make \
    ninja-build \
    python3 \
    python3-dev \
    swig \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Build Zeek
RUN --mount=type=bind,source=/common/buildzeek,target=/tmp/buildzeek /tmp/buildzeek ${VER} ${BUILD_TYPE}

## Compiling OT parsers
RUN --mount=type=bind,source=/common/buildOTplugins,target=/tmp/buildOTplugins /tmp/buildOTplugins


# Make final image
# Final Image reference https://github.com/zeek/zeek/blob/master/docker/final.Dockerfile
FROM debian:trixie-slim as runner

# Version variable. It can be specified when building image with --build-arg otherwise it will use 6.0.4 as default value
ARG VER=8.0.10

# Type of Zeek to build (Production ready or Debug)
ARG BUILD_TYPE=Release

# GEOIP variable. If set to true when building image, it will copy maxmind db to correct directory. Otherwise database won't be copied
ARG GEOIP=false

# Install run time dependencies
RUN apt-get update \
    && apt-get -y install --no-install-recommends \
    ca-certificates \
    # Needed for entrypoint
    cron \
    git \
    # Needed only if using GEOIP (but very light so not conditionally included)
    libmaxminddb0 \
    libpcap0.8 \
    libssl3 \
    # Not sure why needed but very light
    libuv1 \
    libzmq5 \
    python3 \
    python3-git \
    python3-semantic-version \
    python3-websocket \
    # The new ZeroMQ-based cluster backend needs this package. I’m not sure, however, how useful the package above is ("python3-websocket"), but as it doesn’t cause any conflicts, i won’t remove it.
    python3-websockets \
    zlib1g \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/zeek-${VER} /usr/local/zeek-${VER}

# Copy MaxMindDB only if GEOIP enabled
RUN --mount=type=bind,source=/geoip/,target=/tmp/geoip/ \
if [ "${GEOIP}" = true ]; then \
    mkdir /usr/share/GeoIP/; \
    mv /tmp/geoip/*.mmdb /usr/share/GeoIP/; \
fi

RUN ln -s /usr/local/zeek-${VER} /zeek

ENV PATH /zeek/bin/:$PATH
ENV PYTHONPATH /usr/local/zeek-${VER}/lib/zeek/python:$PYTHONPATH
# Added Path to all zeek scripts (including AF_Packet for convenience)
ENV ZEEKPATH /usr/local/zeek-${VER}/share/zeek:/usr/local/zeek-${VER}/share/zeek/policy:/usr/local/zeek-${VER}/share/zeek/site:/usr/local/zeek-${VER}/share/zeek/builtin-plugins:/spicy:/usr/local/zeek-${VER}/share/zeek/builtin-plugins/Zeek_Spicy:/usr/local/zeek-${VER}/lib/zeek/plugins/:/usr/local/zeek-${VER}/lib/zeek/plugins/Zeek_AF_Packet/:/usr/local/zeek-${VER}/lib/zeek/plugins/Zeek_AF_Packet/scripts:$ZEEKPATH
COPY /run.sh ./
COPY /process_pcap_folder.sh ./
RUN chmod +x run.sh \
    && chmod +x process_pcap_folder.sh \
    && mkdir -p /var/log/zeek/spool /var/log/zeek/logs

ENTRYPOINT [ "./run.sh" ]
