---
title: "NixOS Quirks and Solutions"
date: 2021-07-04
sort_by: "date"
author: kotatsuyaki (Ming-Long Huang)
---

This page accumulates all the problems I encountered during the migration from Gentoo to NixOS,
along with the solutions I found.

# Install packages from both stable and unstable channels

Unlike other distros, its 100% safe to mix packages from different channels in one system.

<!-- more -->

```bash
$ sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos-unstable
$ sudo nix-channel --update nixos-unstable
```

Now in the configuration file, import `<nixos-unstable>` and use it as one would do for the default channel:

```nix
{ config, pkgs, ... }:

let
  unstable = import <nixos-unstable> { };
in
{
  environment.systemPackages = with pkgs; [
    unstable.neovim
  ];
}
```

# Overriding the DNS server

The first option I found was [`networking.nameservers`], but adding

```nix
{
  networking.nameservers = [ "8.8.8.8" "8.8.4.4" ];
}
```

to the config didn't work for me, because it generates `resolv.conf` with the Google nameservers
_appended_ after the local DNS server, which is not what I wanted:

```conf
# Generated by resolvconf
nameserver 192.168.0.1
nameserver 8.8.8.8
nameserver 8.8.4.4
options edns0
```

It turned out that since NixOS defaults to using NetworkManager under the hood,
[`networking.networkmanager.insertNameservers`] is the correct option,
since it says "a list of name servers that should be _inserted before the ones_ configured in
NetworkManager or received by DHCP".
Apply it like this.

```nix
{
  networking.networkmanager.insertNameservers = [ "8.8.8.8" "8.8.4.4" ];
}
```

# Running AppImage

Some applications are packaged in the [AppImage](https://appimage.org/) format, which claims to be
_Linux apps that run anywhere_.
However due to the weird (in a good sense) way Nix works, linkers and dynamic libraries that are
normally assumed to be present at certain paths are missing, causing troubles when one tries to
execute an AppImage file.

I've found two solutions to this so far:

1. Use [`appimage-run`]. Install it (locally or globally) and , for example, do

   ```bash
   $ appimage-run Netron-5.0.1.AppImage
   ```

2. Create a derivation using [appimageTools](https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-appimageTools).
   Beware that this is still an unstable API.

# Accessing executable installed from `shell.nix` via Emacs TRAMP

This must be the least supported configuration in the world.

- I'm using [lorri](https://github.com/target/lorri) to create per-project nix environment.
  On different projects, different LSP servers are used, so I'm not willing to install them globally
  in the system configuration.
- It's on a remote host, and I use [Emacs TRAMP](https://www.emacswiki.org/emacs/TrampMode) to
  access it from another host.
- I'm using [lsp-mode](https://emacs-lsp.github.io/lsp-mode/) for autocomplete etc.

These three combined together created a hassle, since if I install `python-language-server` from
my project's `shell.nix`, my Emacs can't see the `pyls` executable via TRAMP.
No matter how I poked around the `tramp-remote-path` variable, `(executable-find "pyls" "/ssh:hostname:")`
always returns `nil`.

The only dirty solution I found is to symlink the LSP server executable to the project's root directory:

```bash
$ ln -s $(which pyls) pyls
```

[`networking.nameservers`]: https://search.nixos.org/options?channel=21.05&show=networking.nameservers&from=0&size=50&sort=relevance&query=nameserver
[`networking.networkmanager.insertnameservers`]: https://search.nixos.org/options?channel=21.05&show=networking.networkmanager.insertNameservers&from=0&size=50&sort=relevance&query=nameserver
[`appimage-run`]: https://search.nixos.org/packages?channel=21.05&show=appimage-run&from=0&size=50&sort=relevance&query=appimage

# Searching options from commandline

```bash
$ man configuration.nix
```

If network connection is available, then just go to https://search.nixos.org/options for them.
