FROM frolvlad/alpine-glibc:latest

MAINTAINER Saoneth <saoneth@gmail.com>

ENV TS3_UID 1000
ENV LANG C.UTF-8

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
