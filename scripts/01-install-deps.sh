#!/bin/bash
# 01-install-deps.sh — 安装 py-xiaozhi 蓝牙语音所需的系统依赖（Debian 12）
set -e
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  bluez \
  pulseaudio pulseaudio-module-bluetooth \
  libasound2-plugins \
  tmux \
  python3-venv python3-pip \
  portaudio19-dev
echo "依赖安装完成"
