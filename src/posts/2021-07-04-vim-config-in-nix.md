---
title: "Merging Neovim Config into Nix Config"
date: 2021-07-04
sort_by: "date"
author: kotatsuyaki (Ming-Long Huang)
---

Recently I've been slowly migrating my dev environments and old configs, which were mainly for use
on Gentoo and Void, to [NixOS](https://nixos.org/).
It turned out that it's possible to integrate my config for Neovim into the Nix config, and it'll be
applied to all users (including when using `sudo`), which is handy.  Here's how:

<!-- more -->

1. Find if all the plugins required is packaged in nixpkgs.  This can be done by:

   ```bash
   $ nix-env -qaPA nixos.vimPlugins | grep 'surround'
   nixos.vimPlugins.vim-operator-surround vimplugin-vim-operator-surround-2018-11-01
   nixos.vimPlugins.surround              vimplugin-vim-surround-2019-11-28
   nixos.vimPlugins.vim-surround          vimplugin-vim-surround-2019-11-28
   ```

2. Package those plugins that are not in nixpkgs.
   For example for [this colorscheme](https://github.com/cormacrelf/vim-colors-github),
   we first use [`nix-prefetch-github`](https://github.com/seppeljordan/nix-prefetch-github) to
   obtain the latest commit hash and sha256 hash.

   ```bash
   $ nix-shell -p nix-prefetch-github --command 'nix-prefetch-github cormacrelf vim-colors-github'
   {
       "owner": "cormacrelf",
       "repo": "vim-colors-github",
       "rev": "ee42a68d95078f5a3d1c0fb14462cc781b244ee2",
       "sha256": "1kvvd38nsbpq7a3lf7yj94mbydyb7yiz3mvwbyf6xlhida3y95p3",
       "fetchSubmodules": true
   }
   ```

   Add a `let` expression on the top of the Nix config with the info obtained.

   ```nix
   let
     vim-colors-github = pkgs.vimUtils.buildVimPlugin {
       name = "vim-colors-github";
       src = pkgs.fetchFromGitHub {
         owner = "cormacrelf";
         repo = "vim-colors-github";
         rev = "ee42a68d95078f5a3d1c0fb14462cc781b244ee2";
         sha256 = "1kvvd38nsbpq7a3lf7yj94mbydyb7yiz3mvwbyf6xlhida3y95p3";
       };
     };
   in {
     environment.systemPackages = with pkgs; [
       # ...
     ];
   }
   ```

3. Add neovim with override in `environment.systemPackages`.

   ```nix
   {
     environment.systemPackages = with pkgs; [
       (pkgs.neovim.override {
         # alias "vi" and "vim" to neovim
         viAlias = true;
         vimAlias = true; 
         configure = {
           # vimrc, pasted as-is
           customRC = ''
             colo github
             set termguicolors bg=light
             set et is si ai rnu hls hidden mouse=a ts=4 sts=4 sw=4
             set clipboard=unnamed,unnamedplus
             nn ; :
             vn ; :
             nn <silent> <CR> :noh<CR><CR>
             syn on
             filet plugin indent on
           '';
           # list of plugins
           packages.myPlugins = with pkgs.vimPlugins; {
             start = [ vim-nix vim-colors-github vim-surround ];
             opt = [];
           };
         };
       })
       # other packages ...
     ];
   }
   ```

... and that's it!
Now the plugins and settings are automatically available to all users on the system.
