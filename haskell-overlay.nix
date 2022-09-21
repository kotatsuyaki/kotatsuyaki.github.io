final: prev:
let
  inherit (prev.stdenv) mkDerivation;
  inherit (prev.lib.trivial) flip pipe;
  inherit (prev.haskell.lib)
    appendPatch
    appendConfigureFlags
    dontCheck
    doJailbreak;

  withPatch = flip appendPatch;
  withFlags = flip appendConfigureFlags;

  haskellCompiler = "ghc902";
in
{
  myHaskellPackages = prev.haskell.packages.${haskellCompiler}.override {
    overrides = hpFinal: hpPrev:
      rec {
        ssg = hpPrev.callCabal2nix "ssg" ./ssg { };
        website = prev.stdenv.mkDerivation {
          name = "website";
          buildInputs = [ ssg ];
          propagatedBuildInputs = with hpPrev; [
            pandoc
            pandoc-crossref
            pandoc-sidenote
          ];
          src = prev.nix-gitignore.gitignoreSourcePure [
            ./.gitignore
            ".git"
            ".github"
          ] ./.;

          LANG = "en_US.UTF-8";
          LOCALE_ARCHIVE = prev.lib.optionalString
            (prev.buildPlatform.libc == "glibc")
            "${prev.glibcLocales}/lib/locale/locale-archive";

          buildPhase = ''
            hakyll-site build --verbose
          '';

          installPhase = ''
            mkdir -p "$out/dist"
            cp -r dist/* "$out/dist"
          '';
        };
      };
  };
}
