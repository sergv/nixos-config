{ config, pkgs, ... }:
{
  config.home-manager.users."${config.sergv.user.name}" = {
    # Disable all home-manager manuals - the manpages fails on WSL because of
    # non-functional Semaphore within Python.
    manual = {
      html.enable = false;
      json.enable = false;
      manpages.enable = false;
    };

    home = {
      sessionPath = [ "$HOME/local/bin" ];
    };

    programs.bash = {
      sessionVariables = {
        "EMACS_SYSTEM_TYPE" = "(linux work)";
      };
    };

    home.packages = [
      pkgs.maxima
    ];
  };
}
