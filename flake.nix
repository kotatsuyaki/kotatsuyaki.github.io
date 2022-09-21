{
  description = "kotatsuyaki's blog";
  nixConfig.bash-prompt = "blog-devshell $ ";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { flake-utils, nixpkgs, self }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        config = { };
        overlays = [ (import ./haskell-overlay.nix) ];
        pkgs = import nixpkgs { inherit config overlays system; };
      in
      rec {
        defaultPackage = packages.website;

        packages = with pkgs.myHaskellPackages; { inherit ssg website; };

        apps.default = flake-utils.lib.mkApp {
          drv = packages.ssg;
          exePath = "/bin/hakyll-site";
        };

        devShell = pkgs.myHaskellPackages.shellFor {
          packages = p: [ p.ssg ];

          buildInputs = with pkgs.myHaskellPackages; [
            ssg

            ormolu
            haskell-language-server
            pkgs.rnix-lsp
            ghci

            pandoc-crossref
            pandoc-sidenote
          ];

          withHoogle = true;
        };
      }
    );
}
