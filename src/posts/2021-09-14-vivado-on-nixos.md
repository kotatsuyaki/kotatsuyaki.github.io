---
title: "Xilinx Vivado on NixOS"
date: 2021-09-14
sort_by: "date"
author: kotatsuyaki (Ming-Long Huang)
---

![](/images/Screenshot_20210917_161801.png)

As much as I dislike proprietary stuff, since it's like a hard requirement of the logic design labs
course, I have no choice but to get Vivado installed on both of my machines.
There aren't many choices when it comes to FPGA programming, anyways.

Fortunately Xilinx provides both Windows and Linux builds, so it's actually possible to run it -
with some effort - on non-officially supported Linux distros.
Some of the guides I've seen:

<!-- more -->

- [for Arch](https://wiki.archlinux.org/title/Xilinx_Vivado)
- [for Gentoo (in Chinese)](https://coldnew.github.io/16cb6a8e/)

-----

This post summarizes the interactive installation process on NixOS.
In theory it's possible to automate most of the process, but here we'll be doing a manual install.

1. Download *Vivado HLx 2020.2: All OS installer Single-File Download*.

   This is a huge 43GB tarball that contains all the necessary files.

   Some may prefer the web installer, but my suggestion is to download everything altogether.
   There're reports of failures occuring during the fetching phase of the web installer, and when
   that happens, everything starts from 0 percent again, which is painful.

2. Extract it `tar xzvf Xilinx_Unified_2020.2_1118_1232.tar.gz`
3. Create a `shell.nix` file for the FHS[^1] entry.

```nix
{ pkgs ? import <nixpkgs> { } }:

(pkgs.buildFHSUserEnv {
  name = "vivado-env";
  targetPkgs = pkgs: (
    with pkgs; [
      ncurses5 zlib libuuid

      bash coreutils zlib stdenv.cc.cc ncurses
      xorg.libXext xorg.libX11 xorg.libXrender xorg.libXtst xorg.libXi xorg.libXft xorg.libxcb xorg.libxcb

      freetype fontconfig glib gtk2 gtk3

      graphviz gcc unzip nettools
    ]
  );
  runScript = ''
    env LIBRARY_PATH=/usr/lib \
      C_INCLUDE_PATH=/usr/include \
      CPLUS_INCLUDE_PATH=/usr/include \
      CMAKE_LIBRARY_PATH=/usr/lib \
      CMAKE_INCLUDE_PATH=/usr/include \
      bash
  '';
}).env
```

4. Drop into the FHS environment using `nix-shell` and switch into the extracted directory.
5. Run `./xsetup -b ConfigGen` and select a product.
6. Go to `$HOME/.Xilinx/install_config.txt` and edit the config file.  Destination of the install
   can be changed there.
7. Install Vivado.
   This took less than 10 minutes on my machine.

   ```
   ./xsetup -a XilinxEULA,3rdPartyEULA,WebTalkTerms -b Install -c $HOME/.Xilinx/install_config.txt`
   ```

And that's it.  Now update the nix expression to launch vivado directly when `nix-shell` is invoked.

```nix
{
  # ...
  runScript = ''
  env LIBRARY_PATH=/usr/lib \
    C_INCLUDE_PATH=/usr/include \
    CPLUS_INCLUDE_PATH=/usr/include \
    CMAKE_LIBRARY_PATH=/usr/lib \
    CMAKE_INCLUDE_PATH=/usr/include \
    $HOME/xilinx/Vivado/2020.2/bin/vivado
  '';
}
```

# Update: Adding the udev rules

To connect to FPGA boards via JTAG, some udev rules are required.
The udev rules can be found in `$PREFIX/Vivado/2020.2/data/xicom/cable_drivers/lin64/install_script/install_drivers`.
They also provide some install scripts, but apparently then won't work on NixOS.
Instead, just copy the content of the rules, and use the `writeTextFile` trivial builder to package them.

```nix
{
  services.udev.packages = [
    (pkgs.writeTextFile {
      name = "xilinx-dilligent-usb-udev";
      destination = "/etc/udev/rules.d/52-xilinx-digilent-usb.rules";
      text = ''
        ATTR{idVendor}=="1443", MODE:="666"
        ACTION=="add", ATTR{idVendor}=="0403", ATTR{manufacturer}=="Digilent", MODE:="666"
      '';
    })
    (pkgs.writeTextFile {
      name = "xilinx-pcusb-udev";
      destination = "/etc/udev/rules.d/52-xilinx-pcusb.rules";
      text = ''
        ATTR{idVendor}=="03fd", ATTR{idProduct}=="0008", MODE="666"
        ATTR{idVendor}=="03fd", ATTR{idProduct}=="0007", MODE="666"
        ATTR{idVendor}=="03fd", ATTR{idProduct}=="0009", MODE="666"
        ATTR{idVendor}=="03fd", ATTR{idProduct}=="000d", MODE="666"
        ATTR{idVendor}=="03fd", ATTR{idProduct}=="000f", MODE="666"
        ATTR{idVendor}=="03fd", ATTR{idProduct}=="0013", MODE="666"
        ATTR{idVendor}=="03fd", ATTR{idProduct}=="0015", MODE="666"
      '';
    })
    (pkgs.writeTextFile {
      name = "xilinx-ftdi-usb-udev";
      destination = "/etc/udev/rules.d/52-xilinx-ftdi-usb.rules";
      text = ''
        ACTION=="add", ATTR{idVendor}=="0403", ATTR{manufacturer}=="Xilinx", MODE:="666"
      '';
    })
  ];
}
```

# References

- [Fhs env for installing xilinx](https://discourse.nixos.org/t/fhs-env-for-installing-xilinx/13150/2)

[^1]: [Filesystem Hierarchy Standard (FHS)](https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard)
      is the standard directory structure adopted by a large number of Linux distributions.
      NixOS isn't among one of them, but still provides [`buildFHSUserEnv`](https://nixos.org/manual/nixpkgs/stable/#sec-fhs-environments)
      as an escape hatch to let users run programs that heavily depend on the standard.
