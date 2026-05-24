# Ubuntu driver

本机是 Ubuntu 26.04 LTS，Desktop session 使用 Wayland。硬件重点是 NVIDIA GPU 和 Realtek Wi-Fi。

## NVIDIA

当前硬件和驱动：

```text
GPU: NVIDIA GeForce RTX 4060 Ti
Driver: 595.71.05
Recommended package: nvidia-driver-595-open
```

检查推荐驱动：

```bash
ubuntu-drivers devices
```

安装推荐驱动：

```bash
sudo ubuntu-drivers install
reboot
```

重启后检查：

```bash
nvidia-smi
```

## Display

显示器配置文件：

```text
~/.config/monitors.xml
```

当前显示配置：

```text
Connector: DP-3
Monitor: PHL 27M2N5810
Resolution: 3840x2160 @ 160Hz
Scale: 125%
```

日常调整直接用 `Settings -> Displays`，不要手写 `monitors.xml`。

## Wi-Fi

当前无线网卡：

```text
Hardware: Realtek RTL8852BE PCIe 802.11ax
Driver: rtw89_8852be
Kernel module: rtw89_8852be
```

本机曾出现 idle suspend 后 Wi-Fi 无法稳定唤醒，kernel log 有 `timed out to flush pci txch` / `timed out to flush queues`。
当前 workaround 是关闭 `rtw89_pci` 的部分 PCIe power-management：

```bash
sudo vim /etc/modprobe.d/rtw89-pci.conf
```

内容：

```text
options rtw89_pci disable_clkreq=Y disable_aspm_l1=Y
```

应用：

```bash
sudo update-initramfs -u
reboot
```

重启后检查，期望都输出 `Y`：

```bash
cat /sys/module/rtw89_pci/parameters/disable_clkreq
cat /sys/module/rtw89_pci/parameters/disable_aspm_l1
```

排查上一轮启动日志：

```bash
journalctl -b -1 -k --no-pager | rg -i 'rtw89|timed out to flush|read rf busy|read swsi busy'
journalctl -b -1 --no-pager | rg -i 'suspend|resume|gnome-shell|gdm|fprintd|power key'
```
