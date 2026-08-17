{ config, pkgs, ... }:
{
  networking = {
    firewall = {
      enable = true;
      allowPing = false;
      extraCommands = ''
        iptables -I OUTPUT 1 -m owner --gid-owner no-internet -j DROP
      '';
    };
  };

  users = {
    # Make sure that users are managed only through configuration.nix
    groups = {
      no-internet = { };
    };
    users = {
      #};
      ## Define a user account. Don't forget to set a password with ‘passwd’.
      #extraUsers = {
      root = {
        hashedPassword = "Yeah, like I'm going to tell you even my password hash";
      };
      sergey = {
        home = "/home/sergey";
        extraGroups = [
          "adm"
          "adbusers"
          "audio"
          # # To make joysticks work, cf https://github.com/libsdl-org/SDL/issues/12397
          # NixOS doesn’t seem to have this group so doesn’t help.
          # "input"
          "netdev"
          "networkmanager"
          # Doesn’t disable internet per se, but I need to be part of the group
          # to be able to run ‘no-internet’ script.
          "no-internet"
          "plugdev"
          "sudo"
          "vboxusers"
          "video"
          "wheel"
        ];
        name                        = "sergey";
        description                 = "sergey"; # "Sergey Vinokurov";
        isNormalUser                = true;
        uid                         = 1000;
        shell                       = pkgs.bash;
        # mkpasswd -m sha-512       <password>
        hashedPassword              = "Yeah, like I'm going to tell you even my password hash";
        openssh.authorizedKeys.keys = [
          "Yeah, like I'm going to tell you even my public key. You'll need to WORK for it."
        ];
      };
    };
  };

}
