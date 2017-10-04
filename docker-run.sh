#!/usr/bin/env bash

set -u
set -e

if [ -z "${DEBUG:-}" ]; then
  DEBUG=false
fi

if [ -z "${JVM_OPTS:-}" ]; then
  JVM_OPTS=""
fi

if [ -z "${JAR_FILE:-}" ]; then
    JAR_FILE="$(ls *-standalone.jar)"
fi

export JVM_OPTS
JVM_OPTS="$(/bin/jvm-opts-with-defaults.sh)"

JAVA=$(which java)

cmd="${JAVA} ${JVM_OPTS} -jar $JAR_FILE $*"

if [ $DEBUG = true ]; then
  echo $cmd
else
  bash -c "${cmd}"
fi
