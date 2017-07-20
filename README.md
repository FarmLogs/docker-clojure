# docker-clojure

[![Docker Repository on Quay](https://quay.io/repository/farmlogs/clojure/status "Docker Repository on Quay")](https://quay.io/repository/farmlogs/clojure)

Based off of the official Clojure docker image, but with `gdal-bin` tools and `docker-run.sh` (for providing command line JVM_OPTS) added.

Example Dockerfile that uses this image:

```
FROM quay.io/farmlogs/clojure

# Copy the project file first
# This allows us to take advantage of caching for the
# deps layer
COPY ./project.clj /app/

WORKDIR /app

RUN lein deps

# Copying the remaining files after the deps are fetched
# means not having to fetch deps again until the project.clj
# is changed
COPY . .

# Create an uberjar
RUN ["/bin/bash", "-c", "lein uberjar && cp target/*-standalone.jar ./"]

# optional, set any custom jvm options
ENV JVM_OPTS="-Duser.timezone=UTC"

# optional, override the default Xmx percentage (default is 50)
ENV JVM_MAX_MEM_RATIO=75

ENTRYPOINT ["/bin/docker-run.sh"]
```
