FROM clojure

MAINTAINER FarmLogs Backend <mwhalen@farmlogs.com>

RUN apt-get -y update \
    && apt-get -y install gdal-bin build-essential libproj-dev

WORKDIR /src

RUN curl -s -O http://www.ftp.cpc.ncep.noaa.gov/wd51we/wgrib2/wgrib2.tgz \
    && tar -zxvf wgrib2.tgz \
    && cd grib2 \
    && make \
    && ln -s /src/grib2/wgrib2/wgrib2 /usr/local/bin/wgrib2

RUN apt-get purge \
    && apt-get autoremove \
    && rm -rf /tmp/*

COPY ./docker-run.sh /app/
