{ config, lib, pkgs, sergv, ... }:
{

  options.sergv.programs.ksysguard = {
    enable = lib.mkEnableOption "Enable KDE's ksysguard process monitoring application";
  };

  config = lib.mkIf config.sergv.programs.ksysguard.enable
    (lib.mkMerge
      [
        {
          nixpkgs.overlays = [ sergv.inputs.ksysguard6-src.overlays.default ];

          home-manager.users."${config.sergv.user.name}".home.packages =
            [
              pkgs.sergv-extensions.ksysguard6
            ];
        }

        (lib.optionalAttrs sergv.isLinux
          {
            # Disable ksgrd_network_helper within security.wrappers
            # since the executable is patched out and does not exist.
            security.wrappers.ksgrd_network_helper = {
              enable = pkgs.lib.mkForce false;
            };
          })
      ]);
}
