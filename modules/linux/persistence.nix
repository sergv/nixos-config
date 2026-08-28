{ config, lib, sergv, ... }:
{
  imports = [ sergv.inputs.impermanence.nixosModules.impermanence ];

  config = lib.mkIf config.sergv.persistence.enable
    {
      environment.persistence."${config.sergv.persistence.permanent-storage-path}" = {
        hideMounts = true;

        directories = [
          "/etc/NetworkManager/system-connections"
          "/var/lib"
          "/var/log"
        ];
        files = [
          "/etc/machine-id"
          "/etc/ssh/ssh_host_rsa_key"
          "/etc/ssh/ssh_host_rsa_key.pub"
          "/etc/ssh/ssh_host_ed25519_key"
          "/etc/ssh/ssh_host_ed25519_key.pub"
        ];
      };

      home-manager.users."${config.sergv.user.name}" = {
        home.persistence = {
          # Heavyweight things from their ows device
          "${config.sergv.persistence.permanent-storage-path}/storage" = {
            hideMounts = true;

            directories =
              builtins.map
                (x: {
                  directory = x;
                  mode      = "0700";
                })
                [
                  "Music"
                  "Pictures"
                  "Videos"
                  "audiobooks"
                  "books"
                  "comics"
                  "films"
                  "gamedev"
                  "games"
                  "manga"
                  "software"
                  "tmp"
                ];
          };

          # Regular persistent things
          "${config.sergv.persistence.permanent-storage-path}" = {
            hideMounts = true;

            directories =
              [

                # {
                #   directory = ".local/share/Steam";
                #   method = "symlink";
                # }

                # Pulseaudio doesn’t like symlinks.
                ".config/pulse"
              ]
              ++
              builtins.map
                (x: {
                  directory = x;
                  mode = "0700";
                })
                [
                  "Documents"
                  "Downloads"
                  "My Games"
                  "London"
                  "VirtualBox VMs"
                  "art"
                  "bicycle"
                  "documents"
                  "dwhelper"
                  "health"
                  "nix"
                  "projects"
                  "recipes"
                  "scripts"
                  "sites"
                  "todo"
                  "torrents"
                  "travelling"
                  "vim"

                  # Supreme Commander FAF
                  # ".gapforever"
                  ".faforever"

                  ".android"
                  ".bitcoin"
                  ".cabal"
                  ".cargo"
                  ".dosbox"
                  ".electrum"
                  ".emacs.d"
                  ".ghc"
                  ".ghc-wasm"
                  ".gnupg"
                  ".gradle"
                  ".isabelle"
                  ".java/.userPrefs"
                  ".litecoin"
                  ".mozilla"
                  ".paradoxlauncher"
                  ".ssh"
                  ".stack"
                  ".thunderbird"

                  ".config/.arduino15"
                  ".config/AndroidStudio3.2"
                  ".config/Google"
                  ".config/PCSX2"
                  ".config/VirtualBox"
                  ".config/Xilinx"
                  ".config/android"
                  ".config/audacious"
                  ".config/bitcoin"
                  ".config/chromium"
                  ".config/dconf"
                  ".config/fontforge"
                  ".config/htop"
                  ".config/ksysguardrc"
                  ".config/keybase"
                  ".config/libreoffice"
                  ".config/mc"
                  ".config/paradox-launcher-v2"
                  ".config/ristretto"
                  ".config/strawberry"
                  ".config/transmission"
                  ".config/vlc"
                  ".config/xfce4"
                  ".local/share/3909"
                  ".local/share/Anki"
                  ".local/share/Anki2"
                  ".local/share/Paradox Interactive"
                  ".local/share/TelegramDesktop"
                  ".local/share/Tyranny"
                  ".local/share/aspyr-media"
                  ".local/share/direnv"
                  ".local/share/docker"
                  ".local/share/keyrings"
                  ".local/share/mc"
                  ".local/share/mime"
                  ".local/share/openmw"
                  ".local/share/qBittorrent"
                  ".local/share/ristretto"
                  ".local/share/strawberry"
                  ".local/share/trash"
                  ".local/share/vlc"
                ];

            files =
              [
                "machine-specific-setup.el"
                "password.org"
                "todo.org"
                "O0DGDxpMBNs.jpg"
                ".aspell.en.prepl"
                ".aspell.en.pws"
                ".bash_history"
                ".rtorrent.rc"
                ".vimrc"
                ".config/Audaciousrc"
                ".config/QtProject.conf"
                ".config/Triblerrc"
                ".local/ghci.conf"
              ]
              ++
              builtins.map
                (x: {
                  file   = x;
                  method = "symlink";
                })
                [
                  # ".emacs"
                ];
          };
        };

        # systemd.user.tmpfiles.rules = [
        #   # "L+ ${homeDir}/.vimrc            0644 -      -     - ${config.sergv.persistence.permanent-storage-path}/home/sergey/.vimrc"
        #   # "L+ ${homeDir}/vim               0644 -      -     - ${config.sergv.persistence.permanent-storage-path}/home/sergey/vim"
        # ];
      };
    };
}
