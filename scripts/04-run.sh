#!/bin/bash
# 04-run.sh — 打补丁、写配置、tmux 启动 py-xiaozhi（单实例）
# 用法：bash 04-run.sh /path/to/py-xiaozhi [运行用户]
set -e
SRC="${1:?用法: $0 /path/to/py-xiaozhi [用户]}"
USER="${2:-$USER}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 1. 打采样率补丁（幂等）
if ! patch -p1 --dry-run -R -d "$SRC" < "$SCRIPT_DIR/../patches/01-samplerate-override.patch" >/dev/null 2>&1; then
  patch -p1 -d "$SRC" < "$SCRIPT_DIR/../patches/01-samplerate-override.patch"
  echo "补丁已应用"
else
  echo "补丁已存在，跳过"
fi

# 2. 写配置文件（模板 -> 真实路径，不覆盖已有）
CONF_DIR="$(runuser -u "$USER" -- bash -c 'echo ~/.local/share/py-xiaozhi/config')"
if [ ! -f "$CONF_DIR/config.json" ]; then
  runuser -u "$USER" -- mkdir -p "$CONF_DIR"
  cp "$SCRIPT_DIR/../config/config.json.example" "$CONF_DIR/config.json"
  runuser -u "$USER" -- bash -c "chown \$(id -u):\$(id -g) $CONF_DIR/config.json"
  echo "已写入默认配置，请检查 $CONF_DIR/config.json"
fi

# 3. 确保单实例，tmux 启动
tmux kill-session -t xiaozhi 2>/dev/null || true
pkill -f "py-xiaozhi.*main.py --mode cli" 2>/dev/null || true
sleep 1
RDIR="/run/user/$(id -u "$USER")"
tmux new-session -d -s xiaozhi \
  "runuser -u $USER -- env XDG_RUNTIME_DIR=$RDIR HOME=$(runuser -u "$USER" -- bash -c 'echo $HOME') $SRC/.venv/bin/python $SRC/main.py --mode cli"
echo "已启动 tmux 会话 xiaozhi。attach: tmux attach -t xiaozhi"
echo "CLI 里按 r+回车说话，x+回车打断，q+回车退出"
