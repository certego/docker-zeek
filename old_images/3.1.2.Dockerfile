FROM debian:buster as builder
LABEL mantainer="f.foschini@certego.net"

ENV WD /scratch
ENV VER 3.1.2

RUN mkdir ${WD}
WORKDIR /scratch

RUN apt-get update && apt-get upgrade -y && echo 2020-05-01
RUN apt-get -y install \
  bison \
  build-essential \
  ca-certificates \
  cmake \
  flex \
  gawk \
  git \
  libcurl4-openssl-dev \
  libgeoip-dev \
  libjemalloc-dev \
  libmaxminddb-dev \
  libncurses5-dev \
  libpcap-dev \
  libssl-dev \
  python-dev \
  swig \
  wget \
  zlib1g-dev \
  --no-install-recommends

ADD ./common/buildzeek ${WD}/common/buildzeek
RUN ${WD}/common/buildzeek zeek ${VER}

RUN echo "===> Compiling af_packet plugin..." \
  cd /usr/src/ \
  && git clone https://github.com/J-Gras/zeek-af_packet-plugin \
  && cd zeek-af_packet-plugin \
  && make distclean \
  && ./configure --with-kernel=/usr \
  --zeek-dist=/usr/src/zeek-${VER}\
  && make -j 4\
  && make install

# Make final image
FROM debian:buster
ENV VER 3.1.2
#install runtime dependencies
RUN apt-get update \
    && apt-get -y install --no-install-recommends libpcap0.8 libssl1.1 libmaxminddb0 python cron \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/zeek-${VER} /usr/local/zeek-${VER}
ADD geoip/*.mmdb /usr/share/GeoIP/
RUN ln -s /usr/local/zeek-${VER} /zeek

ENV PATH /zeek/bin/:$PATH
ADD run.sh ./
ADD process_pcap_folder.sh ./
RUN chmod +x run.sh \
    && chmod +x process_pcap_folder.sh \
    && mkdir -p /var/log/zeek/spool /var/log/zeek/logs

ENTRYPOINT ["./run.sh"]
