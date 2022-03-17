FROM debian:bullseye-slim as builder
LABEL mantainer="f.foschini@certego.net"

ENV WD /scratch
ARG VER=4.0.5

# If directory does not exits, it will be automatically created
WORKDIR ${WD}

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y \
    bind9 \
    bison \
    build-essential \
    ca-certificates \
    cmake  \
    flex \
    g++ \
    gawk \
    gcc \
    git \
    libgoogle-perftools-dev \
    libcurl4-openssl-dev \
    libgeoip-dev \
    libjemalloc-dev \
    libmaxminddb-dev \
    libncurses5-dev \
    libpcap-dev \
    libssl-dev \
    python3-minimal \
    python3.9-dev \
    swig \
    wget \
    # zlib1g-dev same as libz-dev
    zlib1g-dev \ 
    --no-install-recommends


ADD ./common/buildzeek_tcmalloc ${WD}/common/buildzeek
RUN echo "===> Compiling zeek..."
# To enable tcmalloc, --enable-perftools must be passed to ./configure in buildzeek script
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
FROM debian:bullseye
ARG VER=4.0.5

# Install run time dependencies
RUN apt-get update \
    && apt-get -y install \
    --no-install-recommends \
    cron \
    libgoogle-perftools4 \
    libpcap0.8 \
    libssl1.1 \
    libmaxminddb0 \
    python3-minimal \
    python3-git \
    python3-semantic-version \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/zeek-${VER} /usr/local/zeek-${VER}
#ADD geoip/*.mmdb /usr/share/GeoIP/
RUN ln -s /usr/local/zeek-${VER} /zeek

ENV PATH /zeek/bin/:$PATH
ADD run.sh ./
ADD process_pcap_folder.sh ./
RUN chmod +x run.sh \
    && chmod +x process_pcap_folder.sh \
    && mkdir -p /var/log/zeek/spool /var/log/zeek/logs

ENTRYPOINT [ "./run.sh" ]
