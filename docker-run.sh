#!/usr/bin/env bash

set -u
set -e

if [ -z "${DEBUG:-}" ]; then
  DEBUG=false
fi

if [ -z "${JVM_OPTS:-}" ]; then
  JVM_OPTS=""
fi

JAVA=$(which java)

cmd="${JAVA} ${JVM_OPTS} -jar $(ls *-standalone.jar) $*"

if [ $DEBUG = true ]; then
  echo $cmd
else
  bash -c "${cmd}"
fi
