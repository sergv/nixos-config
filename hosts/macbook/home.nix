{ config, pkgs, ... }:
{
  config.home-manager.users."${config.sergv.user.name}" = {
    # home = {
    #   sessionPath = [ "$HOME/local/bin" ];
    # };

    home.packages = [
      # pkgs.maxima
    ];
  };
}
