#!/usr/bin/env bash
set -euo pipefail

PERSIST_DEV="/dev/disk/by-label/EIR_PERSIST"
if [ -e "$PERSIST_DEV" ]; then
  echo "Detected persistence partition at $PERSIST_DEV"
  MNT="/var/mnt/persist"
  mkdir -p "$MNT"
  if ! mountpoint -q "$MNT"; then
    mount "$PERSIST_DEV" "$MNT"
  fi

  # 1. Persistent home directory
  mkdir -p "$MNT/home/eir"
  if [ -z "$(ls -A "$MNT/home/eir" 2>/dev/null)" ]; then
    echo "Initializing fresh persistent /home/eir from base image..."
    cp -a /home/eir/. "$MNT/home/eir/" || true
    chown -R eir:users "$MNT/home/eir" || true
  fi
  mkdir -p /home/eir
  mount --bind "$MNT/home/eir" /home/eir

  # 2. Persistent NetworkManager wifi profiles
  mkdir -p "$MNT/NetworkManager/system-connections"
  mkdir -p /etc/NetworkManager/system-connections
  mount --bind "$MNT/NetworkManager/system-connections" /etc/NetworkManager/system-connections
else
  echo "No EIR_PERSIST partition found. Running in standard ephemeral mode."
fi
