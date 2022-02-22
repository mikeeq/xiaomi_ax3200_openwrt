# Xiaomi Router AX6S / AX3200 OpenWRT

## Overview

I'm planning to add pipeline for building OpenWRT images, as for now you'll only find here a tutorial for installing already built images.

## Tested HW

| Device               | System version        | Model | Production Date | Market |
| -------------------- | --------------------- | ----- | --------------- | ------ |
| Xiaomi Router AX3200 | MiWiFi Release 1.0.71 | RB01  | 09/2021         | EU     |

> Xiaomi AX3200 RB01 EU revision should have Telnet enabled from factory

```bash
# Stock RB01 telnet output
❯ telnet 192.168.31.1
Trying 192.168.31.1...
Connected to 192.168.31.1.
Escape character is '^]'.

XiaoQiang login: root
Password:
```

### Known Issues

- 160Hz wide 5GHz channels don't work [source](https://forum.openwrt.org/t/adding-openwrt-support-for-xiaomi-redmi-router-ax6s-xiaomi-router-ax3200/111085/131?u=mikeeq)
- Smaller coverage area comparing to stock firmware

## Tutorial: How to install OpenWRT

0. I recommend restoring router settings to factory defaults, before installing OpenWRT

1. Finish initial setup by going to <http://192.168.31.1>

2. Check if telnet is enabled on your device

   ```bash
   # Create temporary directory
   mkdir -p xiaomi_openwrt
   cd xiaomi_openwrt

   # Pull scripts for generating telnet password
   curl -Ls https://raw.githubusercontent.com/mikeeq/xiaomi_ax3200_openwrt/main/script.sh -o ./script.sh
   curl -Ls https://raw.githubusercontent.com/mikeeq/xiaomi_ax3200_openwrt/main/password.py -o ./password.py

   # Replace <STOK> with the session token grabbed from the login URL after initial setup
   ## http://192.168.31.1/cgi-bin/luci/;stok=1675d313f8c5d384e191b653c44c5e3a/web/home#router
   ### i.e.: STOK="1675d313f8c5d384e191b653c44c5e3a" bash script.sh
   STOK="<STOK>" bash script.sh

   # look for telnet_en=1 or "telnet":true
   ```

   > If `telnet_en=0` or `"telnet": false`, then telnet is not enabled on your device you need to wait for the [exploit](https://forum.openwrt.org/t/adding-openwrt-support-for-xiaomi-redmi-router-ax6s-xiaomi-router-ax3200/111085/74?u=mikeeq) or use [CH341A programmer](https://forum.openwrt.org/t/adding-openwrt-support-for-xiaomi-redmi-router-ax6s-xiaomi-router-ax3200/111085/151?u=mikeeq)

3. Start SSHd on router using telnet

   ```bash
   # Create telnet terminal session, use TELNET_PASSWORD from script output from previous point
   telnet 192.168.31.1

   # Enable SSH
   nvram set ssh_en=1
   nvram set uart_en=1
   nvram set boot_wait=on
   nvram commit
   sed -i '/flg_ssh.*release/ { :a; N; /fi/! ba };/return 0/d' /etc/init.d/dropbear

   # Set password for root user, `echo -e “<PASSWORD>/n<PASSWORD>” | passwd root` didn't work for me
   passwd root

   # Start SSHd (dropbear)
   /etc/init.d/dropbear enable
   /etc/init.d/dropbear start

   # Test SSH connection, for authentication use password set earlier
   ssh root@192.168.31.1
   # cat /proc/mtd
   ```

4. SCP (copy over SSH) `factory.bin` and `rootfs.ubi` and

   ```bash
   # Create temporary directory
   mkdir -p xiaomi_openwrt_images
   cd xiaomi_openwrt_images

   # Download images from Internet
   curl -Ls https://github.com/mikeeq/xiaomi_ax3200_openwrt/releases/download/v20220222-thorsten97/openwrt-mediatek-mt7622-xiaomi_redmi-router-ax6s-squashfs-factory.bin -o factory.bin
   curl -Ls https://github.com/mikeeq/xiaomi_ax3200_openwrt/releases/download/v20220222-thorsten97/openwrt-mediatek-mt7622-xiaomi_redmi-router-ax6s-squashfs-rootfs.ubi -o rootfs.ubi

   # Copy images over SSH to router
   cd ../
   scp -r xiaomi_openwrt_images root@192.168.31.1:/tmp/
   ```

5. Validate sha256 checksums and flash OpenWRT

   ```bash
   # Open SSH terminal session
   ssh root@192.168.31.1
   cd /tmp/xiaomi_openwrt_images

   # Validate those checksums against checksums found in github releases file sha256
   sha256sum *.bin

   # Set NVRAM flags
   nvram set flag_boot_success=1
   nvram set flag_try_sys1_failed=0
   nvram set flag_try_sys2_failed=0

   # Flash images
   mtd write factory.bin firmware
   mtd write factory.bin firmware1
   mtd write -r rootfs.ubi overlay
   ```

6. After running last command `mtd write -r` router should automatically reboot and after it gets up you can open <http://192.168.1.1> in the browser and try to login (default password is blank/empty) and set root password here: <http://192.168.1.1/cgi-bin/luci/admin/system/admin>

   > If something go wrong make sure that you've tried to restart your NIC to grab fresh IP from DHCP

7. If you're sure that you've bricked your device there'a recovery TFTP mode:
   - You must set the ip address 192.168.31.100 on your pc, and you can use Xiaomi Recovery Tool.
If you use other tftp software, you need rename the firmware by C0A81F02.img and setup dhcp server with 192.168.31.0/24. ([SOURCE](https://forum.openwrt.org/t/adding-openwrt-support-for-xiaomi-redmi-router-ax6s-xiaomi-router-ax3200/111085/164?u=mikeeq>))
   - <https://openwrt.org/toh/xiaomi/xiaomi_redmi_router_ac2100#stock_recovery>
   - <https://gitlab.com/db260179/openwrt-base/-/tree/master/docker>
   - Xiaomi Recovery Tool: <http://miwifi.com/miwifi_download.html>

## Luci Overview

![Luci](images/luci.png)

## SSH Output from successfully flashed OpenWRT

```bash
❯ ssh root@192.168.1.1
root@192.168.1.1's password:


BusyBox v1.35.0 (2022-02-14 13:40:34 UTC) built-in shell (ash)

  _______                     ________        __
 |     | .-----.-----.-----. |  |  |  | .----. |  | _ |
 | --- ||  _  |  -__|     ||  |  |  ||   _||   _|
 |_______||   __|_____|__|__||________||__|  |____|
          |__| W I R E L E S S   F R E E D O M
 -----------------------------------------------------
 OpenWrt SNAPSHOT, r18806-2120cad38d
 -----------------------------------------------------
root@OpenWrt:~# df -h
Filesystem                Size      Used Available Use% Mounted on
/dev/root                14.5M     14.5M         0 100% /rom
tmpfs                   113.7M    944.0K    112.8M   1% /tmp
/dev/ubi0_1              31.6M     56.0K     29.9M   0% /overlay
overlayfs:/overlay       31.6M     56.0K     29.9M   0% /
tmpfs                   512.0K         0    512.0K   0% /dev

root@OpenWrt:/# dmesg | grep -i xia
[    0.000000] Machine model: Xiaomi Redmi Router AX6S
```

## Docs

- <https://forum.openwrt.org/t/adding-openwrt-support-for-xiaomi-redmi-router-ax6s-xiaomi-router-ax3200/111085>
- <https://github.com/openwrt/openwrt/pull/4810/commits/6dc598a880aa79eb2fe5b3e8a04bc23a96256cb2>
- <https://github.com/acecilia/OpenWRTInvasion>
- <https://blog.csdn.net/zhoujiazhao/article/details/102578244>
- <https://openwrt.org/toh/xiaomi/xiaomi_redmi_router_ac2100#stock_recovery>
- <https://openwrt.org/toh/xiaomi/ax3200>
- <https://downloads.openwrt.org/snapshots/targets/mediatek/mt7622/>
- <https://openwrt.org/docs/guide-user/additional-software/imagebuilder>
- <https://openwrt.org/docs/guide-developer/toolchain/use-buildsystem>
- <https://docs.mudfish.net/en/docs/mudfish-cloud-vpn/router-openwrt-install-firmware/>

## Credits

- [@namidairo](https://github.com/namidairo) for adding support for AX3200/AX6S in OpenWRT
- [@thorsten97](https://forum.openwrt.org/u/thorsten97/summary) for building images
