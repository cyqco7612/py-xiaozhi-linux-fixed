# py-xiaozhi-linux 修复版

在 Linux（Debian 12 / 斐讯 N1）上跑 [py-xiaozhi](https://github.com/huangjunsen0406/py-xiaozhi) 的完整修复记录。

上游项目是为桌面/开发环境设计的，在无头 Linux + 蓝牙耳机场景下有几个硬伤，
这里全部修掉，开箱即用。

## 实测环境

- 斐讯 N1（Amlogic S905D），Debian 12 bookworm，内核 6.18.18-trim
- 蓝牙：板载 AP6255（设备树修复后驱动，见 `dtb/`）
- 耳机：Shokz OpenRun（HFP 16kHz 麦克风 + 播放）
- 音频：PulseAudio 16.1（`pulseaudio-module-bluetooth`）
- Python 3.11 venv

## 修复内容

| # | 问题 | 修复 |
|---|------|------|
| 1 | `RuntimeError: 无法找到可用的输入设备`，启动即退出 | 以有音频权限的用户运行（见脚本），音频设备选 `pulse` |
| 2 | ALSA `default` 设备录音无声 | 配置 `input_device_name` / `output_device_name` 为 `pulse` |
| 3 | 蓝牙 HFP 麦克风原生 16kHz，自动检测 44.1kHz 重采样无声 | `patches/01-samplerate-override.patch`：允许配置覆盖采样率，`input_sample_rate: 16000` |
| 4 | 多个实例同时跑，CPU 230%，音频欠载 | 只跑单实例（`scripts/04-run.sh` 用 tmux 单会话） |
| 5 | N1 板载蓝牙无响应 | `dtb/` 修复版设备树：GPIOX_17=96（原 overlay 误用 27=BOOT_1），见 `docs/TROUBLESHOOTING.md` |

## 快速开始

```bash
# 1. 装依赖
sudo bash scripts/01-install-deps.sh

# 2. （N1 专用）换上修复版设备树后重启
sudo cp dtb/meson-gxl-s905d-phicomm-n1-codex-bt.dtb /boot/dtb/amlogic/
# fnEnv.txt 里 fdtfile 指向它，reboot

# 3. 配对蓝牙耳机
bash scripts/02-setup-bluetooth.sh   # 按提示把耳机设为配对模式

# 4. 配置音频（PulseAudio + ALSA）
bash scripts/03-setup-audio.sh

# 5. 打补丁、配 config、启动
bash scripts/04-run.sh /path/to/py-xiaozhi
```

启动后在 tmux 会话里按 `r`+回车说话，`x`+回车打断。
首次运行走官方激活流程，记下 6 位配对码去 https://xiaozhi.me 绑定。

## 目录

- `patches/`：给上游打的补丁（`patch -p1 < patches/01-samplerate-override.patch`）
- `scripts/`：安装/蓝牙/音频/启动脚本
- `config/`：`asoundrc.example`、`config.json.example`（模板，填自己的设备 MAC）
- `dtb/`：N1 修复版设备树二进制
- `docs/TROUBLESHOOTING.md`：完整排查记录

## 许可证

补丁与脚本 MIT；上游 py-xiaozhi 遵循其原仓库许可证。
