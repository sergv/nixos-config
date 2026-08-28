{ config, lib, pkgs, sergv, ... }:
{
  config = lib.mkMerge
    [
      {
        # Recommendations for secure secure shell, https://stribika.github.io/2015/01/04/secure-secure-shell.html
        programs.ssh.extraConfig = ''
          PubkeyAcceptedKeyTypes ssh-ed25519,ssh-rsa
          HostKeyAlgorithms ssh-ed25519,ssh-rsa
          KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256
          Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
          MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256
        '';

        services.openssh = {
          enable      = true;
          extraConfig = "PubkeyAcceptedKeyTypes = ssh-rsa,ssh-ed25519";
        };

        home-manager.users."${config.sergv.user.name}" = {
          programs.ssh = {
            enable = true;

            matchBlocks =
              {
                "github.com" = {
                  hostname     = "github.com";
                  user         = "git";
                  identityFile = config.sergv.user.homeDirectory + "/.ssh/github_sergv_id_rsa";
                };
                "gitlab.com" = {
                  hostname     = "gitlab.com";
                  user         = "git";
                  identityFile = config.sergv.user.homeDirectory + "/.ssh/anon-gitlab-key";
                };
                "gitlab.haskell.org" = {
                  hostname     = "gitlab.haskell.org";
                  user         = "git";
                  identityFile = config.sergv.user.homeDirectory + "/.ssh/haskell-ghc-gitlab-key";
                };
              } //
              builtins.listToAttrs
                (builtins.map
                  (hostname: {
                    name  = hostname;
                    value = {
                      inherit hostname;
                      user         = config.sergv.user.name;
                      identityFile = config.sergv.user.homeDirectory + "/.ssh/macbook.key";
                    };
                  })
                  ["macbook" "macbook-wifi" "macbook-wire"])
              ;
          };
        };
      }

      (lib.optionalAttrs sergv.isLinux
        {
          services.openssh.settings = {
            AllowUsers             = [ config.sergv.user.name ];
            PermitRootLogin        = "no";
            PasswordAuthentication = false;
            UsePAM                 = false;
            X11Forwarding          = true;
          };
        })

    ];
}
