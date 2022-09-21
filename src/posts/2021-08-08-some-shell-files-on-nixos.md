---
title: "A Collection of Several shell.nix Files"
date: 2021-08-08
sort_by: "date"
author: kotatsuyaki (Ming-Long Huang)
---

For a while I've been migrating my old codebases to use Nix and
[lorri](https://github.com/target/lorri) to manage dev environments. Some advantages I've found so
far:

- Self-containedness: the development tools are nicely packed with the project itself, so no more
  globally-installed cli tools that are only used in one project.
- Multiple versions of the same tool: different projects can use different versions of the same
  package.
- The ability to simply `cd` into the project directory and have the development environment
  automatically setup (this is made possible by [direnv](https://github.com/direnv/direnv)).

<!-- more -->

For some programming languages though, environment setup via `shell.nix` may be non-trivial and
requires some searching here and there to be fitured out. Here are some of my `shell.nix` files.

# Rust development

As of the time of writing, rust-analyzer on stable nixpkgs suffers from some subtle bugs, so
`unstable.rust-analyzer` is used instead. `lld` is used to speed up linkage, and `sccache` is used
to cache build results.

For more information, see [rust-overlay](https://github.com/oxalica/rust-overlay).

```nix
{
  pkgs ? (import <nixpkgs> {
    # Rust overlay
    overlays = [
      (import (builtins.fetchTarball {
        url = https://github.com/oxalica/rust-overlay/archive/master.tar.gz;
      }))
    ];
    config.allowUnfree = true;
  }),
  lib ? pkgs.stdenv.lib
}:

let
  unstable = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz") {};
in
  pkgs.mkShell rec {
    buildInputs = with pkgs; [
      # rust
      unstable.rust-analyzer
      (rust-bin.stable.latest.default.override {
        extensions = [ "rust-src" ];
      })

      # optional
      llvmPackages.lld sccache
    ];

    # optional
    RUSTFLAGS = "-C link-arg=-fuse-ld=lld";
    # optional
    RUSTC_WRAPPER = "${pkgs.sccache}/bin/sccache";
  }
```

# Flutter development targeting Linux desktop

This is what I have that works so far - I'm not sure if there's a better solution than the dirty
`$LD_LIBRARY_PATH` trick.

```nix
{ pkgs ? import <nixpkgs> {} }:

let
  flutter-linux-buildtools = with pkgs; [cmake ninja clang pkgconfig];
  flutter-linux-deps = with pkgs; [gtk3 glib lzma pcre util-linux libselinux libsepol libthai libdatrie xorg.libXdmcp xorg.libXtst libxkbcommon epoxy dbus at-spi2-core];
in
  pkgs.mkShell {
    buildInputs = with pkgs; [
      flutter
    ] ++ flutter-linux-buildtools ++ flutter-linux-deps;
    shellHook = ''
      export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${pkgs.wayland}/lib:${pkgs.libglvnd}/lib:${pkgs.xorg.libX11}/lib
      export FLUTTER_SDK=${pkgs.flutter.unwrapped}
    '';
  }
```
