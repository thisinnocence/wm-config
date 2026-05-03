# Ubuntu Driver And Display Status

Ubuntu 26.04 LTS with GNOME Wayland only.

```text
OS: Ubuntu 26.04 LTS
Kernel: 7.0.0-14-generic
Secure Boot: enabled
Session type: Wayland
```

## Summary

The display is now configured for high refresh rate. Current status:

- NVIDIA GPU driver: OK
- Display refresh rate: 160 Hz active
- Wi-Fi driver: OK
- Ethernet driver: OK
- Audio driver: OK
- Power profile: performance
- Failed systemd units: none

## NVIDIA GPU

- Hardware: NVIDIA GeForce RTX 4060 Ti
- Driver: text nvidia-driver-595-open

## Display

Monitor:

```text
Connector: DP-3
Monitor: Philips Consumer Electronics Company 27"
Model: PHL 27M2N5810
Refresh: 3840x2160 @ 160.000 Hz
Scale: 1.5
```

GNOME monitor config:

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

Wi-Fi suspend/resume note:

```text
Issue: system may fail to wake cleanly after idle suspend
Main suspect: rtw89_8852be PCIe power-management instability
Seen in logs:
- timed out to flush pci txch: 0
- timed out to flush queues
Fix applied:
- /etc/modprobe.d/rtw89-pci.conf
- options rtw89_pci disable_clkreq=Y disable_aspm_l1=Y
Status: reboot required after update-initramfs -u
```

After reboot, verify the workaround:

```bash
cat /sys/module/rtw89_pci/parameters/disable_clkreq
cat /sys/module/rtw89_pci/parameters/disable_aspm_l1
```

Expected:

```text
Y
Y
```

If the issue happens again, check:

```bash
journalctl -b -1 -k --no-pager | rg -i 'rtw89|timed out to flush|read rf busy|read swsi busy'
journalctl -b -1 --no-pager | rg -i 'suspend|resume|gnome-shell|gdm|fprintd|power key'
```

If still unstable after this workaround:

```text
Next step: also set disable_aspm_l1ss=Y for rtw89_pci
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

Available profiles:

```bash
performance # for now
balanced
power-saver
```

The active CPU power driver is: `intel_pstate`

## Useful Check Commands

- Check NVIDIA status: `nvidia-smi`
- Check PCI drivers: `lspci -nnk`
