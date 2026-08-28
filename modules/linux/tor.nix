{ config, lib, pkgs, ... }:
{
  options.sergv.tor = {
    enable = lib.mkEnableOption "Enable tor service";

    nickname = lib.mkOption {
      type        = lib.types.str;
      description = "Nickname for tor node";
    };

    email = lib.mkOption {
      type        = lib.types.str;
      description = "Email for tor node";
    };
  };

  config = lib.mkIf config.sergv.tor.enable
    {
      services.tor = {
        enable        = true;
        client.enable = true;

        # Disable GeoIP to prevent the Tor client from estimating the
        # locations of Tor nodes it connects to.
        enableGeoIP   = false;

        # Enable and configure the Tor relay.
        relay = {
          enable = false;
          role   = "relay"; # Set the relay role (e.g., "relay", "bridge")
        };

        # Configure Tor settings
        settings = {
          Nickname    = config.sergv.tor.nickname;
          ContactInfo = config.sergv.tor.email;

          # Bandwidth settings
          MaxAdvertisedBandwidth = "6 MB";
          BandWidthRate          = "5 MB";
          RelayBandwidthRate     = "5 MB";
          RelayBandwidthBurst    = "6 MB";

          # # Restrict exit nodes to a specific country (use the appropriate country code)
          # ExitNodes = "{ch} StrictNodes 1";

          # Reject all exit traffic
          ExitPolicy = [ "reject *:*" ];

          # Performance and security settings
          CookieAuthentication = true;
          AvoidDiskWrites      = 1;
          HardwareAccel        = 1;
          SafeLogging          = 1;
          NumCPUs              = 2;

          # Network settings
          ORPort = [
            443
            9001
          ];
          Dirport = 9002;

          ControlPort = 9051;
        };
      };
    };

}
