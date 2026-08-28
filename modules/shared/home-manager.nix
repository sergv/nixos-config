{ sergv, ... }:
{
  imports =
    [
      (if sergv.isLinux
       then sergv.inputs.home-manager.nixosModules.home-manager
       else sergv.inputs.home-manager.darwinModules.home-manager)
    ];

  config = {
    home-manager = {
      useGlobalPkgs    = true;
      useUserPackages  = true;
      # extraSpecialArgs = home-manager-extra-args args;
      # users.sergey = {
      #   imports = extra-mods;
      # };
    };
  };
}
