# Builder image reference: https://github.com/zeek/zeek/blob/master/docker/builder.Dockerfile
FROM debian:bookworm-slim as builder

# Make the shell split commands in the log so we can determine reasons for
# failures more easily.
SHELL ["/bin/sh", "-x", "-c"]

# Directory to build zeek
ENV WD=/scratch

# Version variable. It can be specified when building image with --build-arg otherwise it will use 6.0.4 as default value
ARG VER=7.0.0

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
    make \
    ninja-build \
    python3 \
    python3-dev \
    swig \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


RUN <<EOF
    printf "Compiling Zeek...\n"
    URL=https://download.zeek.org/zeek-${VER}.tar.gz
    printf "Zeek's download URL %s\n" ${URL}

    # Check Zeek archive existance
    cd /usr/src
    if test ! -e zeek-${VER}.tar.gz; then
        curl -fsLO ${URL}
    fi
    # Check that curl didnt return an error
    if test $? -eq 22; then
        printf "There was an error while downloading Zeek... Exiting.\n"
        exit 1
    fi
    # Remove previous duplicated/homonymes and extract Zeeks data
    tar --recursive-unlink -zxf zeek-${VER}.tar.gz
    cd zeek-${VER}
    # configure reference https://github.com/zeek/zeek/blob/master/configure
    ./configure --prefix=/usr/local/zeek-${VER} --generator=Ninja --build-type="${BUILD_TYPE}" --disable-broker-tests --disable-btest --disable-btest-pcaps --disable-cpp-tests --disable-javascript
    ninja -C /usr/src/zeek-${VER}/build install
EOF

## Compiling OT parsers
RUN <<EOF

# ln -s /usr/local/zeek-${VER}/include/zeek src/zeek is required to successfully use *.pac dependencies
# as a matter of fact includes in *.pac files try to include files in ./*
# This can be inspected by running the following command `binpac -D /path/to/pac/file.pac` (binpac executable must be compiled from auxil folder in zeek src)

declare -A OT_plugins
OT_plugins[ICSNPP-BSAP]="https://github.com/cisagov/icsnpp-bsap.git"
OT_plugins[ICSNPP-Bacnet]="https://github.com/cisagov/icsnpp-bacnet"
OT_plugins[ICSNPP-Ethercat]="https://github.com/cisagov/icsnpp-ethercat"
OT_plugins[ICSNPP-ENIP]="https://github.com/cisagov/icsnpp-enip"
OT_plugins[Zeek-Profinet]="https://github.com/amzn/zeek-plugin-profinet"
OT_plugins[ICSNPP-S7COMM]="https://github.com/cisagov/icsnpp-s7comm"
# To be activated if necessary
#OT_plugins[ICSNPP-OPCUA]="https://github.com/cisagov/icsnpp-opcua-binary"


for plugin in "${!OT_plugins[@]}";
do
printf "===> Compiling %s plugin\n" ${plugin}
cd /usr/src \
&& git clone ${OT_plugins[$plugin]} ${plugin}\
&& cd ${plugin} \
&& ln -s /usr/local/zeek-${VER}/include/zeek src/zeek \
&& ./configure --zeek-dist=/usr/src/zeek-${VER} \
&& make \
&& make install;
/usr/local/zeek/bin/zeek -N | grep -i $(printf ${key} | awk -F- '{ print $1"::"$2 }')
if test $? -eq 0; then
printf "Successfully installed %s plugin.\n" ${plugin}
else
printf "Failed to install %s plugin.\n" ${plugin};
exit 1;
fi
done
EOF


# Make final image
# Final Image reference https://github.com/zeek/zeek/blob/master/docker/final.Dockerfile
FROM debian:bookworm-slim as runner

# Version variable. It can be specified when building image with --build-arg otherwise it will use 6.0.4 as default value
ARG VER=7.0.0

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
    libpython3.11 \
    libssl3 \
    # Not sure why needed but very light
    libuv1 \
    libz1 \
    python3 \
    python3-git \
    python3-semantic-version \
    python3-websocket \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/zeek-7.0 /tmp

# Copy MaxMindDB only if GEOIP enabled
RUN --mount=type=bind,source=/geoip/,target=/tmp/geoip/ <<EOF
if [ "${GEOIP}" = true ]; then \
    mkdir /usr/share/GeoIP/; \
    mv /tmp/geoip/*.mmdb /usr/share/GeoIP/; \
fi
EOF

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
