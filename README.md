# docker-clojure

[![Docker Repository on Quay](https://quay.io/repository/farmlogs/clojure/status "Docker Repository on Quay")](https://quay.io/repository/farmlogs/clojure)

Based off of the official Clojure docker image, but with `gdal-bin`
and `grib2` tools added, and a `docker-run.sh` script for providing
command line JVM_OPTS.

## Default options

Since the JVM doesn't honor cgroups memory limits for calculating the
default heap size when in a container, `docker-run.sh` will add the
following to the `JVM_OPTS` set by the child container:

* if `Xmx` (max heap size) isn't set, it enables [experimental heap
  size calculation][1] based on any cgroup memory limits. By default, it
  will try to use close to 100% of the memory limit. You can Adjust
  that by adding `-XX:MaxRAMFraction=n` to `JVM_OPTS`, where `n` is a
  whole number used to divide the available memory by (so 1 = 100%, 2
  = 50%, etc). Defaults to 1.
* it adds an option that causes the JVM to kill itself if it runs out
  of memory
* it adds properties to enable connecting to JMX remotely. This can be
  disabled by setting `JVM_EXPOSE_JMX` to `"false"`.
* it [disables eliding stack traces][2] for "fast throw" exceptions to
  allow full stack traces to be reported to sentry. This can be
  disabled by setting `JVM_FAST_THROW` to `"true"`.
  
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

# disable exposing JMX, it's exposed by default
ENV JVM_EXPOSE_JMX=false

# optional, will be passed as args to the jvm process started by /bin/docker-run.sh
CMD ["stuff" "and" "things"]
```

[1]: https://dzone.com/articles/running-a-jvm-in-a-container-without-getting-kille
[2]: https://stackoverflow.com/questions/4659151/recurring-exception-without-a-stack-trace-how-to-reset#4659279
