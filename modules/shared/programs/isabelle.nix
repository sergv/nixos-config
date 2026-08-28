{
  config,
  lib,
  pkgs,
  pkgs-opt,
  sergv,
  ...
}:
{
  options.sergv.programs.isabelle = {
    enable = lib.mkEnableOption "Enable Isabelle/HOL proover";
  };

  config.home-manager.users."${config.sergv.user.name}" = lib.mkIf config.sergv.programs.isabelle.enable {

    home.packages = builtins.attrValues (import sergv.packages.isabelle { inherit pkgs; });

  };

}

