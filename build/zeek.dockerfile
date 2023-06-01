# Builder image reference: https://github.com/zeek/zeek/blob/master/docker/builder.Dockerfile
FROM debian:bullseye-slim as builder
LABEL mantainer="f.foschini@certego.net"

# Directory to build zeek
ENV WD=/scratch
# Version variable. It can be specified when building image with --build-arg otherwise it will use 5.0.9 as default value
ARG VER=5.0.9
# GEOIP variable. If set to true when building image, it will copy maxmind db to correct directory. Otherwise database won't be copied
ARG GEOIP=false

# If directory does not exits, it will be automatically created
WORKDIR ${WD}

# Install necessary dependencies
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y \
    bind9 \
    bison \
    ca-certificates \
    ccache \
    cmake  \
    flex \
    g++ \
    gcc \
    git \
    libfl2 \
    libfl-dev \
    libmaxminddb-dev \
    libpcap-dev \
    libssl-dev \
    libz-dev \
    make \
    ninja-build \
    python3-minimal \
    python3-dev \
    python3-pip \
    swig \
    wget \
    --no-install-recommends \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN echo "===> Compiling zeek..."
COPY /common/buildzeek ${WD}/common/buildzeek 
RUN ${WD}/common/buildzeek zeek ${VER}

RUN echo "===> Compiling af_packet plugin..." \
    cd /usr/src \
    && git clone https://github.com/J-Gras/zeek-af_packet-plugin \
    && cd zeek-af_packet-plugin \
    && make distclean \
    && ./configure --with-kernel=/usr \
    --zeek-dist=/usr/src/zeek-${VER} \
    && make -j 4\
    && make install


# Make final image
# Final Image reference https://github.com/zeek/zeek/blob/master/docker/final.Dockerfile
FROM debian:bullseye-slim
ARG VER=5.0.9
ARG GEOIP=false

# Install run time dependencies
RUN apt-get update \
    && apt-get -y install \
    --no-install-recommends \
    ca-certificates \
    cron \
    libmaxminddb0 \
    libpcap0.8 \
    libpython3.9 \
    libssl1.1 \
    libz1 \
    python3-minimal \
    python3-git \
    python3-semantic-version \
    python3-websocket \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/zeek-${VER} /usr/local/zeek-${VER}

# Copy MaxMindDB only if GEOIP enabled
COPY /geoip/*.mmdb /tmp/GEOIP/
RUN if [ "${GEOIP}" = true ]; then \
        mkdir /usr/share/GeoIP/; \
        mv /tmp/GEOIP/*.mmdb /usr/share/GeoIP/; \
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
