# docker-clojure

[![Docker Repository on Quay](https://quay.io/repository/farmlogs/clojure/status "Docker Repository on Quay")](https://quay.io/repository/farmlogs/clojure)

Based off of the official Clojure docker image, but with `gdal-bin`
and `grib2` tools added, and a `docker-run.sh` script for providing
command line JVM_OPTS.

## Default options

Since the JVM can't yet honor cgroups limits when in a container,
`docker-run.sh` will add the following to the `JVM_OPTS` set by the
child container:

* if `Xmx` (max heap size) isn't set and a memory resource limit is
  applied to the container, it calculates an `Xmx` that is 50% of the
  memory limit (the percentage can be overridden by setting
  `JVM_MAX_MEM_RATIO`)
* if a cpu/core resource limit is applied to the container, it sets
  some properties that control the number of threads for GC, etc
* it adds an option that causes the JVM to kill itself if it runs out
  of memory
* it adds properties to enable connecting to JMX remotely. This can be
  disabled by setting `JVM_EXPOSE_JMX` to `"false"`.
  
## Connecting to JMX in a container in kube

1. `kubectl port-forward <pod name> 1099`
2. `jconsole localhost:1099`

## Example Dockerfile

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

# disable exposing JMX, it's exposed by default
ENV JVM_EXPOSE_JMX=false

# optional, will be passed as args to the jvm process started by /bin/docker-run.sh
CMD ["stuff" "and" "things"]
```
