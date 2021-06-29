FROM debian:buster as builder

ENV WD /scratch
ENV VER 4.0.2

RUN mkdir ${WD}
WORKDIR /scratch

RUN apt-get update && apt-get upgrade -y && echo 2021-07-27
RUN apt-get -y install build-essential git bison flex gawk cmake swig libssl-dev libmaxminddb-dev libpcap-dev python3-dev libcurl4-openssl-dev wget libncurses5-dev ca-certificates zlib1g-dev --no-install-recommends

#Checkout zeek

# Build zeek
RUN ln -s /bin/python3 /bin/python
ADD ./common/buildzeek ${WD}/common/buildzeek
RUN ${WD}/common/buildzeek zeek ${VER}



FROM debian:buster
ENV VER 4.0.2
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