#!/bin/sh
#
# Sets default options for the JVM, including:
# * enabling cgroup memory limit detection and auto-generation of heap size
# * exposing jmx via port localhost:1099
# * setting the JVM to kill itself when it runs out of memory
#
# Usage: export JVM_OPTS; JVM_OPTS="$(jvm-opts-with-defaults.sh)"
#
# Env vars evaluated:
#
# JVM_OPTS: Checked for already set options
# JVM_EXPOSE_JMX: if == 'false', jmx is not exposed
# JVM_FAST_THROW: prevents adding the option that tells the JVM to keep
#                 stack traces for "fast throw" exceptions

opts_have() {
    echo "${JVM_OPTS}" | grep -q -- "$1"
    return $?
}

enable_cgroup_limits() {
    if $(opts_have '-Xmx'); then
        return
    fi
    
    echo "-XX:+UnlockExperimentalVMOptions " \
         "-XX:+UseCGroupMemoryLimitForHeap"
}

max_ram_fraction() {
    if $(opts_have '-Xmx'); then
        return
    fi

    if $(opts_have '-XX:MaxRAMFraction'); then
        return
    fi

    echo "-XX:MaxRAMFraction=1"
}

out_of_memory() {
  if $(opts_have '-XX:OnOutOfMemoryError'); then
    return
  fi

  echo '"-XX:OnOutOfMemoryError=kill -9 %p"'
}

expose_jmx() {
  if $(opts_have 'com.sun.management.jmx'); then
    return
  fi

  if [ "x$JVM_EXPOSE_JMX" = "xfalse" ]; then
    return
  fi
    
  echo "-Dcom.sun.management.jmxremote.authenticate=false " \
       "-Dcom.sun.management.jmxremote.ssl=false " \
       "-Dcom.sun.management.jmxremote.local.only=false " \
       "-Dcom.sun.management.jmxremote.port=1099 " \
       "-Dcom.sun.management.jmxremote.rmi.port=1099 " \
       "-Djava.rmi.server.hostname=127.0.0.1"
}

disable_fast_throw() {
  if $(opts_have '-XX:-OmitStackTraceInFastThrow'); then
    return
  fi

  if [ "x$JVM_FAST_THROW" = "xtrue" ]; then
    return
  fi

  echo "-XX:-OmitStackTraceInFastThrow"
}

# Echo options, trimming trailing and multiple spaces
echo "$(enable_cgroup_limits) $(max_ram_fraction) $(out_of_memory) $(disable_fast_throw) $(expose_jmx) $JVM_OPTS" | awk '$1=$1'
