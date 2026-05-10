# Ubuntu driver

## Display

Ubuntu 26.04 LTS 当期是 GNOME Wayland only.

NVIDIA GPU 驱动检查：`nvidia-smi`

显示器配置： `~/.config/monitors.xml`

```text
Connector: DP-3
Monitor: Philips Consumer Electronics Company 27"
Model: PHL 27M2N5810
Refresh: 3840x2160 @ 160.000 Hz
Scale: 1.5
```

## Nic

Wi-Fi 无线网卡:

```bash
# nic info
Hardware: Realtek RTL8852BE PCIe 802.11ax
Driver in use: rtw89_8852be
Kernel module: rtw89_8852be
```

Wi-Fi 网卡曾出现 idle suspend 后无法稳定唤醒的问题。当前判断更像是 `rtw89_8852be` 对 PCIe power-management 的兼容性不稳定。

```text
Kernel log 里出现过：
- timed out to flush pci txch: 0
- timed out to flush queues

已添加 workaround(临时规避) 配置：
- /etc/modprobe.d/rtw89-pci.conf
- options rtw89_pci disable_clkreq=Y disable_aspm_l1=Y

Status:
- 执行 update-initramfs -u 后需要 reboot
- reboot 后确认 kernel module 参数已经生效
```

重启后检查：

```bash
# should be Y
cat /sys/module/rtw89_pci/parameters/disable_clkreq
cat /sys/module/rtw89_pci/parameters/disable_aspm_l1

# check logs for rtw89 related errors
journalctl -b -1 -k --no-pager | rg -i 'rtw89|timed out to flush|read rf busy|read swsi busy'
journalctl -b -1 --no-pager | rg -i 'suspend|resume|gnome-shell|gdm|fprintd|power key'
```
