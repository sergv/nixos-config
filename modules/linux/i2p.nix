{ config, lib, pkgs, sergv, ... }:
{
  options.sergv.i2p = {
    enable = lib.mkEnableOption "Enable i2p service";
  };

  config = lib.mkIf config.sergv.i2p.enable
    {
      networking.firewall.allowedTCPPorts = [
        # For i2p:
        7656 # default sam port
        7070 # default web interface port
        4447 # default socks proxy port
        4444 # default http proxy port
      ];

      services.i2p = {
        enable = true;
      };

      # services.i2pd = {
      #   enable  = true;
      #   address = "127.0.0.1"; # you may want to set this to 0.0.0.0 if you are planning to use an ssh tunnel
      #   proto   = {
      #     http.enable       = true;
      #     socksProxy.enable = true;
      #     httpProxy.enable  = true;
      #   };
      # };

      home-manager.users."${config.sergv.user.name}" = {
        home.packages      = [ pkgs.i2p ];
        xdg.desktopEntries = {
          i2p = {
            type             = "Application";
            exec             = "firefox -P i2p %u";
            terminal         = false;
            name             = "I2P";
            icon             = sergv.icons.i2p;
            comment          = "Anonymous Internet";
            genericName      = "Web Browser";
            mimeType         = [ ];
            categories       = [
              "Network"
              "WebBrowser"
            ];
            # startupWMClass = "I2P";
          };
          # dataFile."applications/i2p.desktop".text = i2pDesktopItem;
        };
      };

    };

}
