{ config, pkgs, flake-self, ... }:
{
  # Will activate home-manager profiles for each user upon login
  # This is useful when using ephemeral installations
  environment.loginShellInit = ''
    [ -d "$HOME/.nix-profile" ] || /nix/var/nix/profiles/per-user/$USER/home-manager/activate &> /dev/null
  '';

  # To be able to manipulate gtk settings.
  programs.dconf.enable = true;

  security.sudo = {
    enable             = true;
    execWheelOnly      = true;
    wheelNeedsPassword = true;
    extraRules         = [
      {
        users    = [ "sergey" ];
        commands = [
          {
            command = "ALL";
            options = [ "SETENV" "NOPASSWD" ];
          }
        ];
      }
    ];
  };

  services.acpid.enable = true;

  # Do not download any new firmware without my input.
  services.fwupd.enable = false;

  services.locate = {
    enable   = true;
    package  = pkgs.mlocate;
    interval = "daily";
  };

  # Enable CUPS to print documents.
  services.printing.enable = false;

  location = {
    # London
    latitude  = 51.508530;
    longitude = -0.076132;
    # Kiev
    # latitude    = "50.45";
    # longitude   = "30.5233";
  };

  systemd = {
    settings.Manager = {
      # File limit.
      DefaultLimitNOFILE      = "8192:10485760";
      # Timeout for starting jobs that hang for any reason.
      DefaultTimeoutStopSec   = "10s";
      DefaultDeviceTimeoutSec = "10s";
    };
    user = {
      extraConfig = ''
        DefaultLimitNOFILE=8192:262144
      '';

      # Disable rootless docker at startup - it will start automatically when docker is used.
      services.docker.wantedBy = pkgs.lib.mkForce [ ];
    };

    tmpfiles.rules = [
      # Never clear /tmp directory
      "q /tmp                    1777 root root - -"
      "q /tmp/tmp                1777 root root - -"
      # Clear /var/tmp whenever as it was by default.
      "q /var/tmp                1777 root root - 30d"
    ];
  };

  system = {
    autoUpgrade = {
      enable = false;
      allowReboot = false;
    };
    # Include everything required to build every package on the system.
    # includeBuildDependencies = true;
  };

  # Disable ksgrd_network_helper within security.wrappers since the executable
  # is patched out and does not exist.
  security.wrappers.ksgrd_network_helper = {
    enable = pkgs.lib.mkForce false;
  };

  system.configurationRevision = flake-self.rev or flake-self.dirtyRev or null;

}
