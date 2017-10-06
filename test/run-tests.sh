#!/bin/bash

run() {
    echo "$(docker run -e DEBUG=true $1 farmlogs/clojure-test:test)"
}

assertions=0
failures=0

track() {
    let assertions+=1
    if [ "$1" -ne 0 ]; then
        let failures+=1
    fi
}


has() {
    echo "$1" | grep -q -- "$2"
    if [ "$?" -ne 0 ]; then
        echo "Expected '$1' to contain '$2'"
        track 1
    else
        track 0
    fi
}

missing() {
    echo "$1" | grep -q -- "$2"
    if [ "$?" -eq 0 ] ; then
        echo "Expected '$1' to not contain '$2'"
        track 1
    else
        track 0
    fi
}

results() {
    echo "$assertions assertions, $failures failures"
    
    if [ "$failures" -gt 0 ]; then
        exit $failures
    fi
}

# defaults
opts="$(run)"
## memory/cgroup
has "$opts" '-XX:+UnlockExperimentalVMOptions'
has "$opts" '-XX:+UseCGroupMemoryLimitForHeap'
has "$opts" '-XX:MaxRAMFraction=1'

## oom
has "$opts" '"-XX:OnOutOfMemoryError=kill -9 %p"'

## disable fast throw
has "$opts" '-XX:-OmitStackTraceInFastThrow'

# custom ram fraction
opts="$(run '-e JVM_OPTS="-XX:MaxRAMFraction=2"')"
has "$opts" '-XX:+UnlockExperimentalVMOptions'
has "$opts" '-XX:+UseCGroupMemoryLimitForHeap'
has "$opts" '-XX:MaxRAMFraction=2'
missing "$opts" '-XX:MaxRAMFraction=1'

# custom Xmx
opts="$(run '-e JVM_OPTS="-Xmx=1m"')"
has "$opts" "-Xmx=1m"
missing "$opts" '-XX:+UnlockExperimentalVMOptions'
missing "$opts" '-XX:+UseCGroupMemoryLimitForHeap'
missing "$opts" '-XX:MaxRAMFraction=1'

# custom oom
opts="$(run '-e JVM_OPTS="-XX:OnOutOfMemoryError=foo"')"
has "$opts" '"-XX:OnOutOfMemoryError=foo"'
missing "$opts" '"-XX:OnOutOfMemoryError=kill -9 %p"'

# enabling jmx
opts="$(run '-e JVM_EXPOSE_JMX=true')"
has "$opts" '-Dcom.sun.management'

# enabling fast throw
opts="$(run '-e JVM_FAST_THROW=true')"
missing "$opts" '-XX:-OmitStackTraceInFastThrow'

# random option survives
opts="$(run '-e JVM_OPTS=-Dwhatevs')"
has "$opts" '-Dwhatevs'

# confirm the default options don't prevent the JVM from starting
out="$(docker run farmlogs/clojure-test:test)"
if [ "$out" = "success" ]; then
    track 0
else
    echo "FAIL: expected 'success', got '$out'"
    track 1
fi

results
