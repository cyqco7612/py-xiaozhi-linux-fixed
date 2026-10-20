#!/bin/bash
# 03-setup-audio.sh — 配置 PulseAudio 蓝牙音频 + ALSA 桥
# 用法：bash 03-setup-audio.sh <耳机MAC> [运行用户]
# 例：bash 03-setup-audio.sh XX:XX:XX:XX:XX:XX cyqco7612
set -e
MAC="${1:?用法: $0 <耳机MAC> [用户]}"
USER="${2:-$USER}"
RDIR="/run/user/$(id -u "$USER")"
PA="runuser -u $USER -- env XDG_RUNTIME_DIR=$RDIR"

# 1. 确保 PulseAudio 在跑
$PA pactl info >/dev/null 2>&1 || $PA pulseaudio --start --log-target=syslog
sleep 2

# 2. 切到 HFP（麦克风用），设为默认输入输出
CARD="bluez_card.${MAC//:/_}"
SRC="bluez_source.${MAC//:/_}.handsfree_head_unit"
SNK="bluez_sink.${MAC//:/_}.handsfree_head_unit"
$PA pactl set-card-profile "$CARD" handsfree_head_unit
sleep 2
$PA pactl set-default-source "$SRC"
$PA pactl set-default-sink "$SNK"
echo "音频 profile: HFP，默认输入输出已设为蓝牙耳机"

# 3. 写 ~/.asoundrc（给 sounddevice/PortAudio 用的别名）
MAC_U="${MAC//:/_}"
runuser -u "$USER" -- bash -c "cat > ~/.asoundrc <<'EOF'
pcm.btmic {
    type pulse
    device \"bluez_source.${MAC_U}.handsfree_head_unit\"
}
pcm.btspeaker {
    type pulse
    device \"bluez_sink.${MAC_U}.handsfree_head_unit\"
}
EOF"
echo "~/.asoundrc 已写好"
echo "验证麦克风：$PA parecord --device=$SRC /tmp/mic-test.raw & sleep 2; kill %1"
