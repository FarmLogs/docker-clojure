FROM clojure

MAINTAINER FarmLogs Backend <mwhalen@farmlogs.com>

ONBUILD RUN apt-get -y update \
            && apt-get -y install gdal-bin

