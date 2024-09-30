# Certego's Zeek Docker image repository

This is the Certego's Zeek Docker image repository.

## Dockerfiles

There are two dockerfiles inside the `build` folder.

1. `zeek.dockerfile` is the production ready image used to build Zeek.
2. `zeekTcmalloc.dockerfile` is a clone of the production ready image used to build Zeek with Tcmalloc.

## Entrypoint

The entrypoint used in both the dockerfiles is:

1. `run.sh`.

## Versioning

By default, when building Zeek image, the version used will be `7.0.2`. 

To improve flexibility, a variable named `VER` has been added to the dockerfile. By means of this variable it's possible to provide the version to build the image against.

So, for instance:

```
docker build -t zeek_test:7.0.2 -f build/zeek.dockerfile --build-arg VER=7.0.2 .
```

By using the build argument `VER` we can specify the version of Zeek we want to build.

## GEOIP

By default, when building Zeek image, GEOIP **will not** be used. However, to keep a certain amount of flexibility, another variable has been added to the dockerfile. This variable, named `GEOIP`, allows to specify whether to enable or disable GEOIP.

So, for instance:

```
docker build -t zeek_test:7.0.2 -f build/zeek.dockerfile --build-arg VER=7.0.2 --build-arg GEOIP=true .
```

By using the build argument `GEOIP` we can enable the use of GEOIP.

To updatde geoip database add new files in geoip folder.

This product includes GeoLite2 data created by MaxMind, available from
<a href="https://www.maxmind.com">here</a>.

## Build & Push

There are two ways to build the image:

1. By using the `build.sh` script with the argument `-b`.
2. Directly using the command: `docker build --build-arg VER=<X.Y.Z> [--build-arg GEOIP=false] -f <build/zeek.dockerfile | build/zeekTcmalloc.dockerfile> -t [certego/zeek:<X.Y.Z>-nogeo | certego/zeek:<X.Y.Z> | certego/zeek:tcmalloc_<X.Y.Z>-nogeo | certego/zeek:tcmalloc_<X.Y.Z>] .`
