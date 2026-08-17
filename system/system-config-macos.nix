{ pkgs, ... }:
{
  system.primaryUser = "sergey";

  users.users.sergey = {
    name        = "sergey";
    description = "sergey"; # "Sergey Vinokurov";
    home        = "/Users/sergey";
    shell       = pkgs.bash;
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
