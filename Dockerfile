FROM saoneth/apline-glibc

ENV LANG=C.UTF-8

ENV GOSU_VERSION 1.10
RUN set -ex; \
        \
        fetchDeps=' \
                dpkg \
                ca-certificates \
                wget \
                gnupg \
        '; \
        apk add --no-cache --virtual .gosu-deps $fetchDeps; \
        \
        dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
        wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
        wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
        \
# verify the signature
        export GNUPGHOME="$(mktemp -d)"; \
        gpg --keyserver p80.pool.sks-keyservers.net --recv-keys "B42F6819007F00F88E364FD4036A9C25BF357DD4"; \
        gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
        rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc; \
        \
        chmod +x /usr/local/bin/gosu; \
# verify that the binary works
        gosu nobody true; \
        \
        apk del .gosu-deps

ENV TEAMSPEAK_URL http://dl.4players.de/ts/releases/3.3.0/teamspeak3-server_linux_amd64-3.3.0.tar.bz2

RUN { \
  apk add --no-cache ca-certificates; \
  addgroup -g 1000 teamspeak; \
  adduser -u 1000 -G teamspeak -h /home/teamspeak -S -D teamspeak -s /bin/sh; \
  \
  apk add --no-cache --virtual .get-deps curl; \
  \
  curl -o /tmp/teamspeak3-server_linux_amd64.tar.bz2 "${TEAMSPEAK_URL}"; \
  \
  apk del .get-deps; \
  \
  tar jxvf /tmp/teamspeak3-server_linux_amd64.tar.bz2 -C /tmp; \
  rm -rf \
    /tmp/teamspeak3-server_linux_amd64.tar.bz2 \
    /tmp/teamspeak3-server_*/redist \
    /tmp/teamspeak3-server_*/doc \
    /tmp/teamspeak3-server_*/serverquerydocs \
    /tmp/teamspeak3-server_*/tsdns \
    /tmp/teamspeak3-server_*/CHANGELOG \
    /tmp/teamspeak3-server_*/LICENSE \
    /tmp/teamspeak3-server_*/ts3server_startscript.sh \
    /home/teamspeak \
  ; \
  mv /tmp/teamspeak3-server_* /home/teamspeak; \
  mkdir \
    /data \
    /data/logs \
    /data/files \
  ; \
  ln -s /data/logs /home/teamspeak/logs; \
  ln -s /data/files /home/teamspeak/files; \
  ln -s /data/ts3server.sqlitedb /home/teamspeak/ts3server.sqlitedb; \
  chown -R teamspeak:teamspeak /home/teamspeak /data; \
}

VOLUME ["/data"]
EXPOSE 9987/udp 10011 30033
ENTRYPOINT ["/usr/local/bin/gosu", "teamspeak:teamspeak", "/home/teamspeak/ts3server_minimal_runscript.sh"]
CMD ["license_accepted=1", "inifile=/data/ts3server.ini", "logpath=/data/logs", "licensepath=/data/", "query_ip_whitelist=/data/query_ip_whitelist.txt", "query_ip_backlist=/data/query_ip_blacklist.txt"]
