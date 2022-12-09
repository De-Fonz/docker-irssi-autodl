# syntax=docker/dockerfile:1.4

FROM alpine:latest

ENV HOME=/home/user \
  PUID="1000" \
  PGID="1000" \
  TZ=Europe\Amsterdam \
  IRSSI_VERSION=1.4.3 \
  AUTODL_IRSSI_VERSION=2.6.2

RUN <<EOT
/bin/sh -c set -eux
addgroup -g ${PGID} autodl
adduser -D -u ${PUID} -h ${HOME} autodl -G autodl
mkdir -p ${HOME}/.irssi	
chown -R autodl:autodl ${HOME}
EOT

ENV LANG=C.UTF-8

RUN apk add --no-cache --virtual .build-deps \
    coreutils \
    gcc \
    glib-dev \
    gnupg \
    libc-dev \
    libtool \
    lynx \
    meson \
    ncurses-dev \
    ninja \
    openssl \
    openssl-dev \
    perl-dev \
    pkgconf \
    tar \
    wget \
    xz \
&& wget "https://github.com/irssi/irssi/releases/download/${IRSSI_VERSION}/irssi-${IRSSI_VERSION}.tar.xz" -O /tmp/irssi.tar.xz \
&& mkdir -p /usr/src/irssi \
&& tar -xf /tmp/irssi.tar.xz -C /usr/src/irssi --strip-components 1 \
&& rm /tmp/irssi.tar.xz \
&& cd /usr/src/irssi \
&& meson -Denable-true-color=yes -Dwith-bot=yes -Dwith-perl=yes -Dwith-proxy=yes Build \
&& ninja -C Build -j "$(nproc)" \
&& ninja -C Build install \
&& cd / \
&& rm -rf /usr/src/irssi \
&& runDeps="$( \
     	scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
        		| tr ',' '\n' \
                | sort -u \
                | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }')" \
&& apk add --no-network --virtual .irssi-rundeps $runDeps \
&& apk del --no-network .build-deps \
&& chown -R autodl:autodl ${HOME}

RUN apk add --update --no-cache \
    perl-archive-zip \
    perl-digest-sha3 \
    perl-html-parser \
    perl-json \
    perl-net-ssleay \
    perl-xml-libxml \
    screen \
    tzdata \
    wget

RUN <<EOT
mkdir -p /autodl
mkdir -p /watch
chown -R autodl:autodl /autodl
chown -R autodl:autodl /watch
EOT

USER autodl

RUN <<EOT
wget https://github.com/autodl-community/autodl-irssi/releases/download/${AUTODL_IRSSI_VERSION}/autodl-irssi-v${AUTODL_IRSSI_VERSION}.zip -O /tmp/autodl-irssi.zip
mkdir -p ${HOME}/.irssi/scripts/autorun
unzip -o /tmp/autodl-irssi.zip -d ${HOME}/.irssi/scripts
cp ${HOME}/.irssi/scripts/autodl-irssi.pl ${HOME}/.irssi/scripts/autorun
mkdir ${HOME}/.autodl
rm /tmp/autodl-irssi.zip
touch ${HOME}/.autodl/autodl.cfg
cd ${HOME}/.autodl
rm -f autodl2.cfg
echo 'load perl' >> ${HOME}/.irssi/startup
mv ~/.autodl/autodl.cfg /autodl
ln -sf /autodl/autodl.cfg ~/.autodl/autodl.cfg
EOT

VOLUME [ "/autodl", "/watch" ]

ENTRYPOINT ["screen","-U","-S","irssi","irssi"]