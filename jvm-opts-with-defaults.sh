#!/bin/sh

# modified from https://github.com/fabric8io-images/java/blob/master/images/alpine/openjdk8/jdk/java-default-options
# and https://github.com/fabric8io-images/java/blob/master/images/alpine/openjdk8/jdk/container-limits

# =================================================================
# Detect whether running in a container and set appropriate options
# for limiting Java VM resources. Also include common tuning options,
# and optionally enable GC diagnostics.
#
# Usage: export JVM_OPTS; JVM_OPTS="$(jvm-opts-with-defaults.sh)"

# Env Vars evaluated:

# JVM_OPTS: Checked for already set options
# JVM_MAX_MEM_RATIO: Ratio use to calculate a default maximum Memory, in percent.
#                     E.g. the default value "50" implies that 50% of the Memory
#                     given to the container is used as the maximum heap memory with
#                     '-Xmx'. It is a heuristic and should be better backed up with real
#                     experiments and measurements.
#                     For a good overviews what tuning options are available -->
#                             https://youtu.be/Vt4G-pHXfs4
#                             https://www.youtube.com/watch?v=w1rZOY5gbvk
#                             https://vimeo.com/album/4133413/video/181900266
# Also note that heap is only a small portion of the memory used by a JVM. There are lot
# of other memory areas (metadata, thread, code cache, ...) which addes to the overall
# size. There is no easy solution for this, 50% seems to be are reasonable compromise.
# However, when your container gets killed because of an OOM, then you should tune
# the absolute values

ceiling() {
  awk -vnumber="$1" -vdiv="$2" '
    function ceiling(x){
      return x%1 ? int(x)+1 : x
    }
    BEGIN{
      print ceiling(number/div)
    }
  '
}

# Based on the cgroup limits, figure out the max number of core we should utilize
cgroups_core_limit() {
  local cpu_period_file="/sys/fs/cgroup/cpu/cpu.cfs_period_us"
  local cpu_quota_file="/sys/fs/cgroup/cpu/cpu.cfs_quota_us"
  if [ -r "${cpu_period_file}" ]; then
    local cpu_period="$(cat ${cpu_period_file})"

    if [ -r "${cpu_quota_file}" ]; then
      local cpu_quota="$(cat ${cpu_quota_file})"
      # cfs_quota_us == -1 --> no restrictions
      if [ "x$cpu_quota" != "x-1" ]; then
        ceiling "$cpu_quota" "$cpu_period"
      fi
    fi
  fi
}

cgroups_max_memory() {
  # High number which is the max limit unti which memory is supposed to be
  # unbounded.
  local max_mem_unbounded="$(cat /sys/fs/cgroup/memory/memory.memsw.limit_in_bytes)"
  local mem_file="/sys/fs/cgroup/memory/memory.limit_in_bytes"
  if [ -r "${mem_file}" ]; then
    local max_mem="$(cat ${mem_file})"
    if [ ${max_mem} -lt ${max_mem_unbounded} ]; then
      echo "${max_mem}"
    fi
  fi
}

opts_have() {
  if echo "${JVM_OPTS}" | grep -q -- "$1"; then
    echo "true"
  fi
}

# Check for memory options and calculate a sane default if not given
max_memory() {
  # Check whether -Xmx is already given in JVM_OPTS. Then we dont
  # do anything here
  if [ "$(opts_have '-Xmx')" = true ]; then
    return
  fi

  # Check if explicitely disabled
  if [ "x$JVM_MAX_MEM_RATIO" = "x0" ]; then
    return
  fi

  # Check for the 'real memory size' and caluclate mx from a ratio
  # given (default is 50%)
  local max_mem="$(cgroups_max_memory)"
  if [ "x$max_mem" != x ]; then
    local ratio=${JVM_MAX_MEM_RATIO:-50}
    local mx=$(echo "${max_mem} ${ratio} 1048576" | awk '{printf "%d\n" , ($1*$2)/(100*$3) + 0.5}')
    echo "-Xmx${mx}m"
  fi
}

cpu_core_tunning() {
  local core_limit="$(cgroups_core_limit)"
  if [ "x$core_limit" != x ]; then
    echo "-XX:ParallelGCThreads=${core_limit} " \
         "-XX:ConcGCThreads=${core_limit} " \
         "-Djava.util.concurrent.ForkJoinPool.common.parallelism=${core_limit}"
  fi
}

out_of_memory() {
  if echo "${JVM_OPTS}" | grep -q -- "-XX:OnOutOfMemoryError"; then
    return
  fi

  echo '"-XX:OnOutOfMemoryError=kill -9 %p"'
}

expose_jmx() {
  if [ "$(opts_have 'com.sun.management.jmx')" = true ]; then
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

# Echo options, trimming trailing and multiple spaces
echo "$(max_memory) $(cpu_core_tunning) $(out_of_memory) $(expose_jmx) $JVM_OPTS" | awk '$1=$1'
