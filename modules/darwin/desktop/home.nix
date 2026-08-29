{ config, pkgs, ... }:
{
  config.home-manager.users."${config.sergv.user.name}" = {
    # home = {
    #   sessionPath = [ "$HOME/local/bin" ];
    # };

    programs.bash = {
      sessionVariables = {
        "EMACS_SYSTEM_TYPE" = "(macos home)";
      };
    };

    home.packages = [
      # pkgs.maxima
    ];
  };
}
