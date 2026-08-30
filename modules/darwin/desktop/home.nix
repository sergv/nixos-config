{ config, pkgs, ... }:
{
  config.home-manager.users."${config.sergv.user.name}" = {
    # home = {
    #   sessionPath = [ "$HOME/local/bin" ];
    # };

    programs.bash = {
      sessionVariables = {
        "EMACS_SYSTEM_TYPE" = "(macos home)";
        "LANG"              = "en_US.UTF-8";
      };
    };

    home.packages = [
      pkgs.djview
      pkgs.xz
    ];
  };
}
