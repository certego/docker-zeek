#!/bin/bash

unset -v BUILD
unset -v PUSH
unset -v IMAGE
unset -v VERSION

usage() {
  echo "Usage: $0 [-b] [-p] -i <production-nogeo|production-geo|tcmalloc-nogeo|tcmalloc> -v 5.0.10"
  echo ""
  echo "Options:"
  echo ""
  echo "-b  [OPTIONAL] build image. Default false"
  echo "-p  [OPTIONAL] push image. Default false"
  echo "-i  which version of the image"
  echo "-v zeek version"
  exit 2
}

BUILD=false
PUSH=false

while getopts bpi:v:h flag
do
    case $flag in
        b) BUILD=true;;
        p) PUSH=true;; 
        i) IMAGE=${OPTARG};;
        v) VERSION=${OPTARG};;
        ?) usage;;
    esac
done

if [[ $OPTIND -eq 1 ]]
then
    usage
fi

if [[ -z "$IMAGE" ]] || [[ -z "$VERSION" ]]; then
    echo "Missing argument -i or -v" >&2
    usage
fi

if [[ $BUILD = true ]];
then
    case $IMAGE in
        production-nogeo) echo "Bulding production (no GEOIP) Zeek ${VERSION}"; docker build --build-arg VER=${VERSION} -f build/zeek.dockerfile -t certego/zeek:${VERSION}-nogeo .;;
        production-geo) echo "Bulding production Zeek with GEOIP ${VERSION}"; docker build --build-arg VER=${VERSION} --build-arg GEOIP=true -f build/zeek.dockerfile -t certego/zeek:${VERSION}-nogeo .;;
        tcmalloc-nogeo) echo "Bulding Tcmalloc (no GEOIP) Zeek ${VERSION}"; docker build --build-arg VER=${VERSION} -f build/zeek.dockerfile -t certego/zeek:tcmalloc_${VERSION}-nogeo .;;
        tcmalloc) echo "Bulding Tcmalloc Zeek with GEOIP ${VERSION}"; docker build --build-arg VER=${VERSION} --build-arg GEOIP=true -f build/zeek.dockerfile -t certego/zeek:tcmalloc_${VERSION} .;;
    esac
fi

if [[ $PUSH = true ]];
then
    case $IMAGE in
        production-nogeo) echo "Pushing certego/zeek:${VERSION}-nogeo (production no GEOIP)"; docker push certego/zeek:${VERSION}-nogeo;;
        production-geo) echo "Pushing certego/zeek:${VERSION} (production with GEOIP)"; docker push certego/zeek:${VERSION};;
        tcmalloc-nogeo) echo "Pushing certego/zeek:tcmalloc_${VERSION}-nogeo (tcmalloc no GEOIP)"; docker push certego/zeek:tcmalloc_${VERSION}-nogeo;;
        tcmalloc) echo "Pushing certego/zeek:tcmalloc_${VERSION} (tcmalloc with GEOIP)"; docker push certego/zeek:tcmalloc_${VERSION};;
    esac
fi