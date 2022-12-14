---
title: "Gentoo Linux on Raspberry Pi 4, Revisited"
date: 2021-02-21
author: kotatsuyaki (Ming-Long Huang)
---

Information for installing Gentoo on the Pi 4 device is scattered here and there
in the Gentoo wiki. Two main sources were used as reference during the
installation.

2. [Raspberry Pi 3 64 Bit Install], which includes the full installation
   process, but is for Pi 3 instead of Pi 4 (they're quite similar, anyways).
1. [Raspberry Pi 4 64 Bit Install], which includes only the Pi4-specific bits.
1. [Official kernel building guide] from the Raspberry Pi Foundation.

The installation was done from Void Linux, but should work on other distros as
well. Get the necessary files first.

<!-- more -->

```sh
$ git clone -b stable --depth 1 https://github.com/raspberrypi/firmware
$ git clone -b rpi-5.10.y --depth 1 https://github.com/raspberrypi/linux
```

# Kernel

We're going to compile the kernel with a cross-compile toolchain. On Void
the `cross-aarch64-linux-gnu` package from XBPS would suffice. The
`CROSS_COMPILE` environment variable in the following commands would depend on
the host distribution we're building the kernel from, and may need changes.

Inside the `linux` directory, load the default vendor configuration first.

```sh
$ ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- make bcm2711_defconfig
```

One config entry that's recommended to be tweaked is `CPU_FREQ_DEFAULT_GOV`,
which defaults to staying on the lowest possible frequency pernamently. Fire up
`make nconfig`, search for it, and set the value to `ondemand` instead. Now
compile the kernel.

```sh
$ ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- make "-j$(nproc)"
```

# Partition and FS

Use your favorite tool (I recommend `cfdisk` or `fdisk`) to partition the SD
card. The first partition should be bootable vfat primary partition. An
example output of `fdisk` looks like this.

```
Device         Boot  Start       End   Sectors  Size Id Type
/dev/mmcblk0p1 *      2048    526335    524288  256M  b W95 FAT32
/dev/mmcblk0p2      526336 125042687 124516352 59.4G 83 Linux
```

Format the first partition as FAT32 (don't forget that `-F 32`!).

```sh
$ sudo mkfs.vfat -F 32 /dev/mmcblk0p1
```

As for the rootfs, originally I thought using [F2FS] may be a great idea since
it's specifically designed for flash memory-based devices including SD cards.
However, it seems that
[F2FS doesn't handle power outages well][rpi-sd-card-storage-considerations],
so eventually I still went for the classical ext4. Both journaling and CRC32C
metadata checksuming are enabled here to make it more robust against
corruptions. `-i 8192` to create an inode for every two 4KB blocks.

```sh
$ sudo mkfs.ext4 -i 8192 -O has_journal,metadata_csum /dev/mmcblk0p2
```

# Installation

Now mount both the rootfs and boot partition. I'll call them `/mnt/rpigentoo`
and `/mnt/rpigentoo/boot`. Download stage3 tarball as usual and then unpack it
inside the rootfs.

```sh
$ links 'https://www.gentoo.org/downloads/mirrors/'
$ # Choose a mirror, navigate to latest stage3-arm64 tarball, press `d` and wait
$ sudo tar xpvf stage3-*.tar.xz \
    --xattrs-include='*.*' --numeric-owner \
    -C /mnt/rpigentoo
```

Install the Portage tree.

```sh
$ curl -LO 'http://distfiles.gentoo.org/snapshots/portage-latest.tar.bz2'
$ tar xvpf portage-latest.tar.bz2 --strip-components=1 \
    -C /mnt/rpigentoo/var/db/repos/gentoo
```

Install the kernel. All kernel images present before installtion should be
removed beforehand to ensure that the device actually boot with `kernel8.img`.
The firmware will happily load the 32-bit `kernel7.img` by default, so this is
necessary.

```sh
$ sudo rm /mnt/rpigentoo/boot/kernel*.img
$ sudo cp arch/arm64/boot/Image /mnt/rpigentoo/boot/kernel8.img
```

Install the firmware. Copy content of `/boot/` from the firmware repository
directly.

```sh
$ sudo cp -rv firmware/boot/* /mnt/rpigentoo/boot/
```

Install the device tree.

```sh
$ sudo cp -v arch/arm64/boot/dts/broadcom/bcm2711-rpi-4-b.dtb \
    /mnt/rpigentoo/boot/
```

The Gentoo wiki suggests to also install fresh copy of device tree overlays from
the kernel repository, while the firmware we've just installed already include
them. Their SHA1 digests seem to be identical, so this step was skipped.

# Configurations before Boot

Of course we need `/mnt/rpigentoo/etc/fstab`.

```txt
/dev/mmcblk0p1 /boot vfat noauto,noatime 1 2
/dev/mmcblk0p2 / ext4 defaults,noatime 0 1
```

And for the Pi to boot properly we need `cmdline.txt` and `config.txt`.

```
# cmdline.txt
root=/dev/mmcblk0p2 rootfstype=ext4 console=tty1 fsck.repair=yes rootwait
# config.txt
disable_overscan=1
hdmi_drive=2
```

# Additional: Get Online

- Ethernet

  For ethernet, no additional firmware is needed, but unfortunately the
  conventional `dhcpcd` isn't present in the stage 3 tarball. Busybox comes to
  the rescue.

  ```sh
  $ busybox udhcpc -i eth0
  ```

  One may be tempted to install dhcpcd at this point, but `emerge` exploded with
  some cryptic `TypeError: 'NoneType' object is not iterable` messages. It
  turned out to be triggered by wrong system datetime, since the Pi lacks an
  RTC. Use `date --set yyyy-mm-dd` to manually adjust datetime and it worked.

- WiFi

  Additional firmware needed. The firmware files resides in the
  `sys-firmware/raspberrypi-wifi-ucode` package, but some files inside it
  conflicts with `kernel/linux-firmware`. The Gentoo Wiki suggests to

  1. (Re-)emerge `linux-firmware` with `savedconfig` USE flag set.
  2. Comment out several broadcom-related files from
     `/etc/portage/savedconfig/sys-kernel/linux-firmware-*`.

  ```sh
  $ for name in brcmfmac43430 brcmfmac43436 brcmfmac43455 brcmfmac43456 \
    do \
        sed -i '/www/ s/^#*/#/' "$name" \
    done
  ```

  3. Re-emerge `linux-firmware`.
  4. Finally emerge `raspberr-wifi-ucode`

  After a reboot `wlan0` shows up in `ip -a` output.

[raspberry pi 4 64 bit install]: https://wiki.gentoo.org/wiki/Raspberry_Pi4_64_Bit_Install
[raspberry pi 3 64 bit install]: https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install
[official kernel building guide]: https://www.raspberrypi.org/documentation/linux/kernel/building.md
[f2fs]: https://en.wikipedia.org/wiki/F2FS
[rpi-sd-card-storage-considerations]: https://www.kevinwlocke.com/bits/2018/04/28/rpi-sd-card-storage-considerations/#f2fs
[ext4 metadata checksums]: https://ext4.wiki.kernel.org/index.php/Ext4_Metadata_Checksums

<!-- Enforce line length limit -->
<!-- vim: set colorcolumn=80: -->
