FROM alpine:3.4

MAINTAINER Saoneth <saoneth@gmail.com>

ENV TS3_UID 1000
ENV LANG C.UTF-8

# Install glibc
RUN ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    ALPINE_GLIBC_PACKAGE_VERSION="2.23-r3" && \
    ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    apk add --no-cache --virtual=.build-dependencies wget ca-certificates && \
    wget \
        "https://raw.githubusercontent.com/andyshinn/alpine-pkg-glibc/master/sgerrand.rsa.pub" \
        -O "/etc/apk/keys/sgerrand.rsa.pub" && \
    wget \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    apk add --no-cache \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    \
    rm "/etc/apk/keys/sgerrand.rsa.pub" && \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true && \
    echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh && \
    \
    apk del glibc-i18n && \
    \
    rm "/root/.wget-hsts" && \
    apk del .build-dependencies && \
    rm \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"

# Install Teamspeak
RUN apk --no-cache add curl coreutils \
  && TEAMSPEAK_VERSION="$(curl -s 'http://dl.4players.de/ts/releases/' | sed -n 's/.*href="\([^"]*\).*/\1/p' | grep '^[0-9]' | sort -V | tail -n 1 | cut -d/ -f1)" \
  && echo "Version: $TEAMSPEAK_VERSION" \
  && TEAMSPEAK_FILE="$(curl -s "http://dl.4players.de/ts/releases/$TEAMSPEAK_VERSION/" | sed -n 's/.*href="\([^"]*\).*/\1/p' | grep '.run' | grep amd64)" \
  && wget -O /tmp/teamspeak3-server_linux_amd64.run "http://dl.4players.de/ts/releases/$TEAMSPEAK_VERSION/$TEAMSPEAK_FILE" \
  && chmod +x /tmp/teamspeak3-server_linux_amd64.run \
  && apk del curl coreutils \
  && sed -i'' 's/MS_PrintLicense()/mo5g4mo5m45/g' /tmp/teamspeak3-server_linux_amd64.run \
  && sed -i'' 's/MS_PrintLicense//g' /tmp/teamspeak3-server_linux_amd64.run \
  && sed -i'' 's/mo5g4mo5m45/MS_PrintLicense()/g' /tmp/teamspeak3-server_linux_amd64.run \
  && /tmp/teamspeak3-server_linux_amd64.run --nox11 --nochown --target /home/teamspeak \
  && mkdir -p /home/teamspeak/data/logs \
  && ln -s /home/teamspeak/data/logs /home/teamspeak/logs \
  && mkdir -p /home/teamspeak/data/files \
  && ln -s /home/teamspeak/data/files /home/teamspeak/files \
  && ln -s /home/teamspeak/data/ts3server.sqlitedb /home/teamspeak/ts3server.sqlitedb \
  && addgroup -g ${TS3_UID} teamspeak \
  && adduser -u ${TS3_UID} -G teamspeak -h /home/teamspeak -S -D teamspeak \
  && chown -R teamspeak:teamspeak /home/teamspeak

USER teamspeak
ENTRYPOINT ["/home/teamspeak/ts3server_minimal_runscript.sh"]
CMD ["inifile=/home/teamspeak/data/ts3server.ini", "logpath=/home/teamspeak/data/logs","licensepath=/home/teamspeak/data/","query_ip_whitelist=/home/teamspeak/data/query_ip_whitelist.txt","query_ip_backlist=/home/teamspeak/data/query_ip_blacklist.txt"]

VOLUME ["/home/teamspeak/data"]

# Expose the Standard TS3 port, for files, for serverquery
EXPOSE 9987/udp 10011 30033
