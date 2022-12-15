#!/bin/sh

if [ -n "${PGID}" ] && [ "${PGID}" != "$(id -g autodl)" ]; then
  echo "Switching to PGID ${PGID}..."
  sed -i -e "s/^autodl:\([^:]*\):[0-9]*/autodl:\1:${PGID}/" /etc/group
  sed -i -e "s/^autodl:\([^:]*\):\([0-9]*\):[0-9]*/autodl:\1:\2:${PGID}/" /etc/passwd
fi
if [ -n "${PUID}" ] && [ "${PUID}" != "$(id -u autodl)" ]; then
  echo "Switching to PUID ${PUID}..."
  sed -i -e "s/^autodl:\([^:]*\):[0-9]*:\([0-9]*\)/autodl:\1:${PUID}:\2/" /etc/passwd
fi

mkdir -p /autodl
mkdir -p /watch

ln -sf /autodl/autodl.cfg ~/.autodl/autodl.cfg

chown -R autodl:autodl ${HOME}
chown -R autodl:autodl /autodl
chown -R autodl:autodl /watch

sudo -u autodl screen -U -S irssi irssi