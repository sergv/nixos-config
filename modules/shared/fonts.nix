{ config, lib, pkgs, sergv, ... }:
{
  config = {
    fonts = lib.mkMerge
      [
        {
          packages =
            let
              my-fonts = import sergv.packages.fonts { inherit pkgs; };
            in
            builtins.attrValues my-fonts;
        }

        (lib.optionalAttrs sergv.isLinux
          {
            fontconfig  = {
              enable          = true;
              hinting.style   = "full";
              antialias       = true;
            };
          })
      ];
  };
}
