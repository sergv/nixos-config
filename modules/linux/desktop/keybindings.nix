{ config, lib, pkgs, sergv, ... }:
{
  options.sergv.desktop.keybindings = {
    enable = lib.mkEnableOption "Enable desktop-orinted keybindings and packages";
  };

  config = lib.mkIf config.sergv.desktop.keybindings.enable
    {
      home-manager.users."${config.sergv.user.name}" =
        let
          wmctrl-pkg = pkgs.wmctrl;

          scripts = import sergv.packages.scripts {
            inherit pkgs;
            wmctrl = wmctrl-pkg;
          };
        in

        {
          services.sxhkd = {
            enable      = true;
            keybindings = import ./sxhkd-keybindings.nix {
              inherit wmctrl-pkg;
              inherit (scripts) wm-sh;
            };
          };

          home.packages =
            [
              wmctrl-pkg
              scripts.wm-sh
            ];
        };
    };
}
