# Ubuntu Driver And Display Status

Checked on Ubuntu 26.04 LTS with GNOME Wayland.

## Summary

The main drivers are loaded correctly and the system is using the recommended NVIDIA driver. The display is now configured for high refresh rate.

Current status:

- NVIDIA GPU driver: OK
- Display refresh rate: 160 Hz active
- Wi-Fi driver: OK
- Ethernet driver: OK
- Audio driver: OK
- Power profile: performance
- Failed systemd units: none

## System

```text
OS: Ubuntu 26.04 LTS
Kernel: 7.0.0-14-generic
Secure Boot: enabled
Session type: Wayland
```

## NVIDIA GPU

Hardware:

```text
NVIDIA GeForce RTX 4060 Ti
PCI ID: 10de:2803
```

Driver in use:

```text
nvidia
```

Installed driver package:

```text
nvidia-driver-595-open
```

Ubuntu recommended driver:

```text
nvidia-driver-595-open
```

NVIDIA runtime check:

```text
NVIDIA-SMI: working
Driver Version: 595.58.03
CUDA Version: 13.2
GPU display active: yes
```

Notes:

- The system is not using Nouveau for the active GPU driver.
- The installed NVIDIA driver matches Ubuntu's recommended driver for this GPU.
- GNOME Shell is running on the NVIDIA GPU.

## Display

Monitor:

```text
Connector: DP-3
Monitor: Philips Consumer Electronics Company 27"
Model: PHL 27M2N5810
Serial: WDA2441002335
```

Current real Wayland mode:

```text
3840x2160 @ 160.000 Hz
Scale: 1.5
```

XWayland/scaled view:

```text
5120x2880 @ 159.95 Hz
```

Available high refresh modes detected by GNOME Mutter:

```text
3840x2160 @ 160.000 Hz
3840x2160 @ 144.000 Hz
3840x2160 @ 119.880 Hz
```

The display was changed from 60 Hz to 160 Hz with this GNOME Mutter command:

```bash
gdbus call --session \
  --dest org.gnome.Mutter.DisplayConfig \
  --object-path /org/gnome/Mutter/DisplayConfig \
  --method org.gnome.Mutter.DisplayConfig.ApplyMonitorsConfig \
  1 2 \
  "[(0, 0, 1.5, 0, true, [('DP-3', '3840x2160@160.000', {})])]" \
  "{'layout-mode': <1>}"
```

Saved GNOME monitor config:

```text
~/.config/monitors.xml
rate: 160.000
scale: 1.5
```

## Network

Wi-Fi:

```text
Hardware: Realtek RTL8852BE PCIe 802.11ax
Driver in use: rtw89_8852be
Kernel module: rtw89_8852be
```

Ethernet:

```text
Hardware: Realtek RTL8111/8168/8211/8411 PCI Express Gigabit Ethernet
Driver in use: r8169
Kernel module: r8169
```

## Audio

Intel onboard audio:

```text
Hardware: Intel Raptor Lake High Definition Audio Controller
Driver in use: snd_hda_intel
Kernel modules: snd_soc_avs, snd_sof_pci_intel_tgl, snd_hda_intel
```

NVIDIA HDMI/DisplayPort audio:

```text
Hardware: NVIDIA AD106M High Definition Audio Controller
Kernel audio modules loaded
```

## Power Profile

Current profile:

```text
performance
```

Available profiles:

```text
performance
balanced
power-saver
```

The active CPU power driver is:

```text
intel_pstate
```

## Health Checks

Systemd failed units:

```text
0 loaded units listed
```

Driver recommendation check:

```bash
ubuntu-drivers devices
```

Result:

```text
nvidia-driver-595-open - distro non-free recommended
```

## Useful Check Commands

Check NVIDIA status:

```bash
nvidia-smi
```

Check Ubuntu recommended drivers:

```bash
ubuntu-drivers devices
```

Check PCI drivers:

```bash
lspci -nnk
```

Check power profile:

```bash
powerprofilesctl get
powerprofilesctl list
```

Check current GNOME Wayland display mode:

```bash
gdbus call --session \
  --dest org.gnome.Mutter.DisplayConfig \
  --object-path /org/gnome/Mutter/DisplayConfig \
  --method org.gnome.Mutter.DisplayConfig.GetCurrentState
```

Check XWayland scaled display view:

```bash
xrandr --query
```
