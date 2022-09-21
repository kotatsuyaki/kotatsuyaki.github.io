---
title: "Setup Podman on Gentoo Linux"
date: 2020-09-06
author: kotatsuyaki (Ming-Long Huang)
---

Recently I wanted to migrate from Docker to rootless podman on my Gentoo install, but ended up jumping through multiple loopholes during the setup.
Simply put, if you're encountering error messages like this

```
Error: container_linux.go:345: starting container process caused "process_linux.go:281: applying cgroup configuration for process caused \"mountpoint for devices not found\""
: OCI runtime error
```

, then there's a high chance that there are some essential kernel options missing.

<!-- more -->

First, re-configure the kernel in order to support `runc`.

```sh
cd /usr/src/linux
make menuconfig
```

Use [`check-config.sh`](https://github.com/opencontainers/runc/blob/master/script/check-config.sh) as a reference to check whether all needed flags are set. Note that `CONFIG_NF_NAT_IPV4` and `CONFIG_NETFILTER_XT_MATCH_IPVS` aren't present in kernel 5.4 anymore, so just ignore them being in `missing` state.

Recompile and install the kernel. You should be very confortable doing this now.

```sh
make -j2; sudo make modules_install; sudo make install
```

Now emerge the `libpod` package. You may need to [unmask some packages](https://wiki.gentoo.org/wiki/Knowledge_Base:Unmasking_a_package):

```
# /etc/portage/package.accept_keywords
app-emulation/conmon ~amd64
app-emulation/libpod ~amd64
app-emulation/slirp4netns ~amd64
sys-fs/fuse-overlayfs ~amd64

# Emerge the package
sudo emerge -avq app-emulation/libpod
```

Reboot and Podman should now be working.

Source: <https://wiki.gentoo.org/wiki/Libpod>
