{ config, pkgs, pkgs-opt, lib, sergv, ... }:
{
  options.sergv.desktop = {
    dev.haskell.host-ghc-versions = lib.mkOption {
      type        = lib.types.nullOr (lib.types.listOf lib.types.str);
      example     = ''["ghc912", "ghc914", "default"]'';
      default     = null;
      description =
        ''
          Names of attributes produced by haskell-nixpkgs-improvements denoting GHC versions to add to system.

          null means don’t filter anything out and select all known versions.
        '';
    };

    dev.haskell.tools = lib.mkOption {
      type        = lib.types.nullOr lib.types.attrs;
      description = "Derived haskell tools for use by other parts of config.";
    };
  };

  config =
    let
      haskell-tools =
        let
          pkgs-haskell =
            sergv.inputs.haskell-nixpkgs-improvements.lib.prepare-haskell-tools-pkgs
              {
                inherit (sergv) pkgs-pristine;
                pkgs = pkgs-opt;
                overlays = [ sergv.inputs.haskell-nixpkgs-improvements.overlays.host ];
              };
          # pkgs-cross-win = pkgs-opt.appendOverlays [ sergv.inputs.haskell-nixpkgs-improvements.overlays.cross-win ];
          pkgs-cross-win = null;
        in
        sergv.inputs.haskell-nixpkgs-improvements.lib.mk-haskell-tools {
          inherit (sergv) system;
          vanilla-pkgs   = pkgs-haskell;
          cross-win-pkgs = pkgs-cross-win;
        };

      select-ghc-versions = all-versions:
        let selected = config.sergv.desktop.dev.haskell.host-ghc-versions;
        in
        if selected == null
        then all-versions
        else
          builtins.foldl'
            (acc: key: acc // { "${key}" = builtins.getAttr key all-versions; })
            {}
            selected;

      all-haskell-tools =
        pkgs.lib.attrsets.unionOfDisjoint haskell-tools.tools
          (select-ghc-versions haskell-tools.ghc.host);
      # (pkgs.lib.attrsets.unionOfDisjoint haskell-tools.ghc.host haskell-tools.ghc.cross-win);

    in
    {
      sergv.desktop.dev.haskell.tools = haskell-tools;

      home-manager.users."${config.sergv.user.name}" = {
        home.packages = builtins.attrValues all-haskell-tools;
      };
    };
}

