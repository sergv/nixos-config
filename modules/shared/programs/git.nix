{ config, lib, pkgs, sergv, ... }:
{

  options.sergv.programs.git = {
    enable = lib.mkEnableOption "Enable git configuration";

    proxy = lib.mkOption {
      type        = lib.types.nullOr (lib.types.submodule {
        options = {
          proxy = lib.mkOption {
            type        = lib.types.str;
            example     = "http://LOGIN:PASSWORD@HOST:PORT";
            description = "Proxy URL";
          };

          sslverify = lib.mkOption {
            type        = lib.types.bool;
            example     = "true";
            description = "Whether to check SSL connections aganist certificate";
          };

          proxyAuthMethod = lib.mkOption {
            type        = lib.types.str;
            example     = "basic";
            description = "Authentification type";
          };

          sslCAInfo = lib.mkOption {
            type        = lib.types.path;
            description = "Path to certificate file";
          };

          sslCAPath = lib.mkOption {
            type        = lib.types.path;
            description = "Path to certificate file";
          };
        };
      });
      description = "Tell git how to connect through proxy";
    };
  };

  config = lib.mkMerge
    [
      {
        home-manager.users."${config.sergv.user.name}" = {
          # programs.git.signing.key = "~/.ssh/signing_key.pub";
          # programs.git.signing.format = "ssh";
          # programs.git.signing.signByDefault = true;

          # todo:
          # url."git@github.com:".pushInsteadOf = "https://github.com/";
          # core.precomposeunicode = true;
          # core.untrackedCache = true;
          # core.preloadindex = true;
          programs.git = {
            enable  = true;
            signing = lib.mkIf (config.sergv.user.gpgKey != null) {
              key           = config.sergv.user.gpgKey;
              signByDefault = true;
            };
            ignores = [
              ".eproj-info"
              "cabal-project*.local"
              "dist-newstyle*"
              "dist"
              "*~"
              "*.bak"
            ];
            settings = {
              alias = {
                "lg"  = "log --graph --abbrev-commit --decorate --date=relative --format=format:'%C(red)%h %G?%C(reset)%C(yellow)%d%C(reset) %C(white)%s%C(reset) - %C(dim white)%an%C(reset) %C(green)(%ar)%C(reset)'";
                "lgm" = "lg --no-merges";
                "ch"  = "checkout";
                "st"  = "status";
                "co"  = "commit";
                "me"  = "merge";
                "br"  = "branch";
                "m"   = "merge";
              };
              user = {
                name  = config.sergv.user.name;
                email = config.sergv.user.email;
              };
              advice = {
                # Disable `git status' hints on how to stage, etc.
                statusHints         = false;
                graftFileDeprecated = false;
              };
              branch = {
                # When branching off a remote branch, automatically let the local
                # branch track the remote one.
                autosetupmerge = true;
              };
              color = {
                ui = true;
              };
              diff = {
                # Make git diff use mnemonic prefixes (Index, Work tree, etc) instead
                # of standard a/ & b/ prefixes.
                mnemonicprefix = true;
                # Show more informative diff when submodules are involved.
                submodule = "log";
              };
              merge = {
                # Always show a diffstat at the end of merge.
                stat = true;
              };
              rebase = {
                # Always show a diffstat at the end of rebase.
                stat = true;
              };
              rerere = {
                enabled = true;
                # Autostage files solved by rerere
                autoupdate = true;
              };
              status = {
                # Provide more information on sumbodule changes in "git status"
                submoduleSummary = true;
              };
              pull = {
                # Automatically rebase when doing "git pull" but preserve local merges.
                # This is the value for git < 2.34
                #rebase = preserve
                # This is the value for git >= 2.34
                rebase = "merges";
                # Fetch submodules when superproject retrieves commit that updates
                # submodule's reference.
                recurseSubmodules = "on-demand";
              };
              fetch = {
                # Fetch submodules when superproject retrieves commit that updates
                # submodule's reference.
                recurseSubmodules = "on-demand";
              };
              push = {
                default = "simple";
                # Check that all submodule commits that current commit to be pushed
                # references are already pushed somewhere.
                recurseSubmodules = "check";
              };
              init = {
                defaultBranch = "master";
              };
              safe = {
                # Let me decide what is considered ‘dubious ownership in
                # repository’, i.e. git, shut the fuck up.
                directory = "*";
              };
            };
          };
        };
      }

      (lib.mkIf (config.sergv.programs.git.proxy != null)
        {
          home-manager.users."${config.sergv.user.name}" = {
            programs.git = {
              settings = {
                http  = config.sergv.programs.git.proxy;
                https = config.sergv.programs.git.proxy;
              };
            };
          };

          # Done in config
          # nixpkgs.overlays =
          #   let
          #     # Make git invoked via nixpkgs’s fetchgit work behind proxy.
          #     improve-fetchgit-overlay = final: old: {
          #       fetchgit =
          #         let
          #           # From https://stackoverflow.com/questions/58169512/call-fetchgit-without-ssl-verify
          #           fetchgit-improved = old.fetchgit // {
          #             __functor = self : args :
          #               (old.fetchgit.__functor self args).overrideAttrs (oldAttrs: {
          #                 GIT_SSL_NO_VERIFY         = !config.sergv.programs.git.proxy.sslverify;
          #                 GIT_HTTP_PROXY_AUTHMETHOD = config.sergv.programs.git.proxy.proxyAuthMethod;
          #                 https_proxy               = config.sergv.programs.git.proxy;
          #               });
          #           };
          #
          #         in fetchgit-improved;
          #     };
          #   in
          #   [ improve-fetchgit-overlay ];
        })
    ];
}
