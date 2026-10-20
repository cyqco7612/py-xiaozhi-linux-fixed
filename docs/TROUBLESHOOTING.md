# 排查记录

## 1. 蓝牙耳机连不上：`br-connection-profile-unavailable`

**现象**：`bluetoothctl connect` 报 `org.bluez.Error.Failed br-connection-profile-unavailable`，
`btmon` 里连 HCI 包都没有，BlueZ 根本没动手。

**根因**：bluetoothd 重启后，A2DP profile 的 `a2dp_source_server_probe` 没跑，
`server->source_enabled` 为 false，`a2dp_sink_connect` 直接返回 `-EPROTONOSUPPORT`。
日志：`a2dp-sink profile connect failed: Protocol not available`。

**解决**：确认 `bluetoothd` 启动日志里有
`a2dp_sink_server_probe() / a2dp_source_server_probe()` 且 profile 状态从
`unavailable -> disconnected`。若没有，重启 bluetoothd 再看。
（另：PulseAudio 重启后要在 bluetoothd 之后重注册 endpoint，
顺序错了也会触发这个问题。）

## 2. 配对时 `Failed to register agent object`

配对前先 `agent on` + `default-agent`，否则部分耳机配对无响应。

## 3. PulseAudio 不认蓝牙声卡

`module-bluetooth-discover` 只在设备**连接事件**时建卡。
若先连蓝牙后起 PA，断开重连一次即可。

## 4. py-xiaozhi `无法找到可用的输入设备`

上游用 `sounddevice`（PortAudio→ALSA）枚举设备。
无头 Linux 上必须以**跑 PulseAudio 的那个用户**启动，
且配置 `input_device_name: "pulse"`（ALSA `default` 的录音是哑的）。

## 5. 能录到但全是静音：采样率

蓝牙 HFP 麦克风原生 16kHz。PortAudio 对 `pulse` 设备上报
`default_samplerate=44100`，py-xiaozhi 照单全收，
ALSA 的 16k→44.1k 重采样直接出静音。
修复：`patches/01-samplerate-override.patch` 让配置里的
`input_sample_rate` 覆盖自动检测值，设为 16000。

## 6. `ALSA lib pcm.c: underrun occurred`（声音卡顿）

`ps` 看是不是起了多个 py-xiaozhi 实例。
之前每次 `tmux kill-session` 没杀干净，4 个实例把 CPU 吃到 230%。
只留一个，`scripts/04-run.sh` 会先清场。

## 7. N1 板载蓝牙无响应（GPIO 编号）

AP6255 的 BT_REG_ON 是 GPIOX_17。**不要**按 bank 连续脑补
（GPIOX_0=10 ⇒ GPIOX_17=27 是错的，27 是 BOOT_1/eMMC 引脚）。
查 `include/dt-bindings/gpio/meson-gxl-gpio.h` 实数：**GPIOX_17=96**。
`dtb/` 里是改好的设备树，直接替换 `/boot/dtb/amlogic/` 下同名文件并改 `fnEnv.txt` 的 `fdtfile`。

## 8. CLI 交互

- `r`+回车：开始/停止说话（光发 `r` 不按回车会被当文本）
- `x`+回车：打断
- `q`+回车：退出
