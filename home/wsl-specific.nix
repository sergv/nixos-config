{
  pkgs,
  git-proxy-conf,
  ...
}:
{
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

  programs.git = {
    signing = {
      signByDefault = pkgs.lib.mkForce false;
    };
    settings = {
      user = {
        # TODO: set up user and email
        name  = pkgs.lib.mkForce "todo";
        email = pkgs.lib.mkForce "todo@example.com";
      };
      http  = git-proxy-conf;
      https = git-proxy-conf;
    };
  };

  home.packages = [
    pkgs.maxima
  ];
}
