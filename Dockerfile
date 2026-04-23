ARG DEBIAN=trixie
FROM debian:${DEBIAN}
ARG DEBIAN=trixie

ARG VERSION=2.5.37
ARG TARGETPLATFORM
ARG BTRFS
ARG ZFS

COPY entrypoint.sh /usr/bin/

RUN URL=https://hndl.urbackup.org/Server/${VERSION} && \
    case ${TARGETPLATFORM} in \
         "linux/amd64")  URL=$URL/urbackup-server_${VERSION}_amd64.deb  ;; \
         "linux/arm64")  URL=$URL/urbackup-server_${VERSION}_arm64.deb  ;; \
         "linux/arm/v7") URL=$URL/urbackup-server_${VERSION}_armhf.deb  ;; \
         "linux/386" | "linux/i386")   URL=$URL/debian/${DEBIAN}/urbackup-server_${VERSION}_i386.deb   ;; \
    esac \
    && dry="http://deb.debian.org/debian ${DEBIAN} contrib" \
    && echo "deb $dry\ndeb-src $dry" >/etc/apt/sources.list.d/${DEBIAN}-contrib.list \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y wget adduser \
    && wget -q "$URL" -O /root/urbackup-server.deb \
    && apt-get remove -y wget \
    && apt-get autoremove -y \
    && echo "urbackup-server urbackup/backuppath string /backups" \
            | debconf-set-selections \
    && apt-get install -y --no-install-recommends \
            /root/urbackup-server.deb \
            ${BTRFS:+btrfs-progs} \
            ${ZFS:+zfsutils-linux} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
            /etc/apt/sources.list.d/${DEBIAN}-contrib.list \
            /root/urbackup-server.deb \
    && cp -R /usr/share/urbackup /web-backup \
    && chmod +x /usr/bin/entrypoint.sh

EXPOSE 55413
EXPOSE 55414
EXPOSE 55415
EXPOSE 35623/udp

# /usr/share/urbackup will not be exported to a volume by default, but it still can be bind mounted
VOLUME [ "/var/urbackup", "/var/log", "/backups" ]
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD ["run", "-v", "warn", "-g", "20971520"]
