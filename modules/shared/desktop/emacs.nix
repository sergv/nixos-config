{ config, pkgs, pkgs-opt, lib, sergv, ... }:
{
  config =
    let
      select-emacs = x:
        if sergv.isDarwin
        then x.bytecode
        else x.native;

      emacs = select-emacs (sergv.inputs.dotemacs.lib.mk-emacs-config {
        inherit (pkgs) system;
        haskell-tools = config.sergv.desktop.dev.haskell.tools;
        arch          = config.sergv.native-optimizations.gccArch;
        pkgs          = pkgs-opt;
      });

      macos-app = sergv.utils.make-macos-app {
        inherit pkgs;
        name              = "Emacs";
        version           = emacs.built-config.version;
        shell-script-path = emacs.built-config + "/bin/emacs";
        icon-path         = emacs.raw + "/Applications/Emacs.app/Contents/Resources/Emacs.icns"; #emacs.icon;
        bundle-identifier = "org.gnu.Emacs";
        copyright         = "Copyright © 2026 Sergey Vinokurov, All Rights Reserved.";
      };
    in lib.mkMerge
      [
        {
          home-manager.users."${config.sergv.user.name}" = {
            xdg =
              lib.optionalAttrs sergv.isLinux {
                desktopEntries = {
                  emacs = emacs.desktop-entry;
                };
                # dataFile."applications/emacs.desktop".text = emacsDesktopItem;
              };

            home.packages = [ emacs.built-config ];
          };
        }

        (lib.optionalAttrs sergv.isDarwin {
          environment.systemPackages = [ macos-app ];
        })
      ];
}
