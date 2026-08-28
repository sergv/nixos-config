{ config, ... }:
{
  config = {
    home-manager.users."${config.sergv.user.name}" = {
      programs.bash = {
        enable = true;
        historyControl = [
          "ignorespace"
          "ignoredups"
          "erasedups"
        ];
        historyFileSize = 100000;

        shellOptions = [
          "histappend"
          "checkwinsize"
          "globstar"
        ];
        initExtra =
          # Note that bash variables in there are quoted with '',
          # strip them before feeding to bash
          #export PROMPT_COMMAND="''${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a"
          ''
            export PROMPT_COMMAND="history -a"

            nix_shell_prompt() {
                # Check if IN_NIX_SHELL variable is set.
                if [[ -v IN_NIX_SHELL ]]; then
                    echo "[nix]"
                fi
            }

            export PS1='$(nix_shell_prompt)\u@\h:\w\$ '

            function genpasswd {
                local len="$1"
                tr -dc 'A-Za-z_0-9:$#!@*+|' </dev/urandom | head -c "''${len:-20}" | cat && echo
            }

            function openurl {
                local file="$(mktemp -u --tmpdir urls/tmp.XXXXXXXX)"
                local dir="''${TMPDIR:-/tmp}/urls"
                [[ ! -d "''${dir}" ]] && mkdir -p "''${dir}"
                wget -k "$1" -O "$file"
                if [[ -f "$file" ]]; then
                    firefox -new-tab "$file"
                else
                    echo "url $1 not downloaded"
                fi
            }

            # Download site recursively
            function download-site () {
                local url="$1"
                if [[ -z "$url" ]]; then
                    echo "usage: download-site URL"
                    return
                fi
                # --sockets=1 --connection-per-second=1 --max-rate=65536
                httrack --mirror --connection-per-second=1 --max-rate=65536 --structure=1 --keep-alive "$url"
            }

            function hp2pdf () {
                if [[ "$#" != 1 || "$1" != *.hp ]]; then
                    echo "usage: hp2pdf <hp-file>" >&2
                    return
                fi
                filename="$1"
                abs_file="$(readlink -f $1)"
                echo hp2ps -M -c -d "$abs_file" #-g -y
                hp2ps -M -c -d "$abs_file" #-g -y
                echo ps2pdf "''${filename%.hp}.ps"
                ps2pdf "''${filename%.hp}.ps"
                okular "''${filename%.hp}.pdf"
            }

          '';

        shellAliases = {
          "igrep"               = "grep -iHn --color=auto";
          "grep"                = "grep -Hn --color=auto";
          "egrep"               = "grep -EHn --color=auto";
          "fgrep"               = "grep -FHn --color=auto";

          "ls"                  = "ls --color=always";
          "lla"                 = "ls --human-readable -AlFa --color=always";
          "ll"                  = "ls --human-readable -AlF --color=always";
          "la"                  = "ls -A --color=always";
          "l"                   = "ls -CF --color=always";

          # PS that shows full command lines and process tree.
          "ps-full"             = "ps auxfww";

          ".."                  = "cd ..";
          "..."                 = "cd ../..";
          "...."                = "cd ../../..";

          "diff"                = "diff --unified --recursive --ignore-tab-expansion --ignore-blank-lines";
          "diffw"               = "diff --unified --recursive --ignore-tab-expansion --ignore-space-change --ignore-blank-lines";

          "disk-usage"          = ''if command -v filelight >/dev/null 2>&1 then filelight; elif command -v baobab >/dev/null 2>&1; then nohup dbus-run-session baobab >/dev/null; else echo "Cannot find neither filelight nor baobab executables to show disk usage" >&2; fi'';
        };
        sessionVariables = {
          "HIE_BIOS_CACHE_DIR"        = "/tmp/dist/hie-bios";
          "EMACS_ROOT"                = "${config.sergv.user.homeDirectory}/.emacs.d";
          "EMACS_WRITABLE_ROOT"       = "${config.sergv.user.homeDirectory}/.emacs.d";
          "CCACHE_COMPRESS"           = "1";
          "CCACHE_DIR"                = "/tmp/.ccache";
          "CCACHE_NOSTATS"            = "1";
          # So that latex will pick up .cls/.sty files from current directory
          "TEXINPUTS"                 = ".:";
          "TMPDIR"                    = "/tmp";
          "EMAIL"                     = config.sergv.user.email;
          "BASHRC_ENV_LOADED"         = "1";
          # ‘nix-shell’ likes to change prompt. ‘trix’ uses ‘nix-shell’ as underlying mechanism
          # so is affected too, while ‘nix develop’ doesn’t so set up this variable to make
          # ‘trix develop’ # behave more like ‘nix develop’.
          "NIX_SHELL_PRESERVE_PROMPT" = "1";
        };
      };

    };
  };
}
