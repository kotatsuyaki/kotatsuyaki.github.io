---
title: NixOS Guide, with Nix Flakes
description: ""
date: 2021-09-25
author: kotatsuyaki (Ming-Long Huang)
enable-toc: true
---

Hello, Internet.
It's been a long time since my last post,
and it's also been over a year since I started diving into the ecosystem of Nix.
This post is an adaptation of [the official NixOS installation manual][nixos-manual-install],
intended to serve as a reference whenever I introduce NixOS to people.

<!-- more -->

:::{.note .blue}
|     |
| --- |
| ℹ️ This guide assumes the readers to have experiences in 1) installating other Linux distributions and in 2) basic usages of `git`. Details for common procedures are omitted, with the main focus being the Nix-specific bits. |
:::

# Preface

## Why Yet Another NixOS Guide?

### Flakes Makes Nix *Actually* Reproducible

NixOS is a Linux distribution based on the Nix package manager,
and has always been focusing on the reproducibility of packages and environments.
To quote from the frontpage of nixos.org,

> Nix builds packages in isolation from each other. This ensures that they are reproducible and don't have undeclared dependencies, so if a package works on one machine, it will also work on another.

However, NixOS, when used in the traditional way, can often be *non-reproducible* unless extra care is taken.
The upcoming *Nix Flakes* feature fixes the issue,
by defining an easy and standardized way to make derivations[^derivations] reproducible and composable.

### The Official Guide Doesn’t Use Flakes

As of this writing, [the official installation guide of NixOS][nixos-manual-install] neither embraces nor mentions Flakes,
and still uses the traditional [Nix channels] mechanism for selecting NixOS versions,
which is a sensible decision given the experimental nature of Flakes.
However, since the whole point of using NixOS is to have reproducible computing environments,
it would be much better if the beginners don't have to learn the traditional, non-reproducible way of doing things,
just to unlearn it in favor of the new way afterwards.
I want to set up [the pit of success][pit-of-success] so that beginners use Nix in an idiomatic way without even thinking about it,
and that's what drove me to write up this guide.

[nixos-manual-install]: https://nixos.org/manual/nixos/stable/#sec-installation
[Nix channels]: https://nixos.wiki/wiki/Nix_channels
[pit-of-success]: https://scribe.rip/the-pit-of-success-cfefc6cb64c8

[^derivations]: ["Derivations" in Nix](https://nixos.org/manual/nix/stable/language/derivations.html) are functions describing build processes.
Most of the time they are analogous to *packages* in other Linux distributions.

## Reasons to or Not to Use NixOS

You may want to try out NixOS if any of the following applies:

- TODO

NixOS may not be for you if any of the following applies:

- TODO


# Installation Guide

## Choosing a Channel and Obtaining the Image

Nixpkgs provides multiple *channels*, which are really just branches in their git repository providing
different level of stability and freshness of the packages.
About every six months, a *stable channel* of Nixpkgs is released, with names like `nixos-22.05` and
`nixos-22.11` indicating the time around which the version is stabilized.

## Connecting to the Internet (Optional)

TODO

## Partitioning and Formatting the Disk

TODO

## Generating and Editing the Config

TODO

## Installing

TODO


# Basic Usage Guide

This section covers how to perform some tasks under NixOS.

## Installing Packages Systemwide

TODO

## Managing Per-Project Dependencies

TODO

## The Escape Hatches

TODO

<!-- vim: set ft=pandoc.markdown: -->
