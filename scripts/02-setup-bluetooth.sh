#!/bin/bash
# 02-setup-bluetooth.sh — 扫描、配对、信任、连接蓝牙耳机
# 用法：bash 02-setup-bluetooth.sh [MAC]
# 不给 MAC 则扫描并列出，让你挑
set -e
MAC="${1:-}"

if [ -z "$MAC" ]; then
  echo "请把耳机设为配对模式，开始扫描 15 秒..."
  bluetoothctl --timeout 15 scan on | grep -iE "new device" || true
  echo "--- 已发现设备 ---"
  bluetoothctl devices
  echo "用法：bash $0 <MAC>"
  exit 0
fi

bluetoothctl <<EOF
agent on
default-agent
pair $MAC
trust $MAC
connect $MAC
quit
EOF
echo "配对完成：$MAC"
bluetoothctl info "$MAC" | grep -E "Paired|Trusted|Connected"
