_:
{
  config = {

    security.pam.services.sudo_local = {
      enable      = true;
      touchIdAuth = true;
      reattach    = true;
    };

    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    system.stateVersion = 6;

    # nix.extraOptions = ''
    #   gc-keep-derivations = true
    #   gc-keep-outputs = true
    #   min-free = 17179870000
    #   max-free = 17179870000
    #   log-lines = 128
    # '';

    system.defaults = {
      # Disable the "Are you sure you want to open this application?" dialog
      LaunchServices.LSQuarantine = false;

      dock = {
        # Whether to automatically rearrange spaces based on most recent use
        mru-spaces                = false;

        # show-process-indicators   = false; # do not show process indicators
        # show-recents              = false; # do not show recent applications
        autohide                  = true; # automatically put away the dock when not in use
        autohide-delay            = 0.1;
        autohide-time-modifier    = 0.5;
        expose-animation-duration = 0.5; # dock resize time
        mineffect                 = "scale"; # set the minimization animation to scaling
        minimize-to-application   = true; # minimize to app icon
        orientation               = "bottom";

        # 1 - disabled
        # 3 - display all windows of focused app
        wvous-tr-corner           = 1; # top right hot corner
        wvous-tl-corner           = 1; # top left hot corner
        wvous-br-corner           = 1; # bottom right hot corner
        wvous-bl-corner           = 1; # bottom left hot corner
        # persistent-apps =
        #   [
        #     "/System/Applications/Apps.app"
        #     "/Applications/Nix Apps/Google Chrome.app"
        #     "/Applications/Xcode.app"
        #     "/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app"
        #   ];
      };

      finder = {
        AppleShowAllExtensions         = true; # show all file extensions by default
        AppleShowAllFiles              = false; # don’t show hidden files
        CreateDesktop                  = false; # do not show icons on Desktop
        FXEnableExtensionChangeWarning = false; # do not show warnings when changing file extensions
        FXPreferredViewStyle           = "icnv"; # list folder contents as icons
        NewWindowTarget                = "Home"; # open new finder windows at
        ShowPathbar                    = true; # show the pathbar
        ShowStatusBar                  = true; # show statusbar
        _FXEnableColumnAutoSizing      = true; # automatically expand columns to fit filenames
        _FXShowPosixPathInTitle        = true;
      };

      screensaver = {
        # Require password immediately after sleep or screen saver begins
        askForPassword = true;
        askForPasswordDelay = 0;
      };

      trackpad = {
        Clicking                = true;
        TrackpadRightClick      = true;
        TrackpadThreeFingerDrag = false;
      };

      CustomUserPreferences = {
        NSGlobalDomain = {
          AppleActionOnDoubleClick = "Fill";
        };

        "com.apple.desktopservices" = {
          # Avoid creating .DS_Store files on network or USB volumes
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores     = true;
        };

        "com.apple.finder" = {
          # Keep Finder animations
          DisableAllAnimations = false;
          # Sidebar order
          SidebarZoneOrder1 = [
            "favorites"
            "devices"
            "locations"
            # "icloud_drive"
            "tags"
          ];
          # Disable iCloud synchronization.
          FXICloudDriveEnabled   = false;
          FXICloudDriveDesktop   = false;
          FXICloudDriveDocuments = false;
        };

        "com.apple.systempreferences" = {
          # Disable Resume system-wide
          NSQuitAlwaysKeepsWindows = false;
        };

        # "com.apple.symbolichotkeys" = {
        #   AppleSymbolicHotKeys = {
        #     # disable "save picture of screen as a file" (cmd + shift + 3)
        #     "28" = { enabled = false; };
        #     # disable "copy picture of screen to the clipboard" (ctrl + cmd + shift + 3)
        #     "29" = { enabled = false; };
        #     # disable "save picture of selected area as a file" (cmd + shift + 4)
        #     "30" = { enabled = false; };
        #     # disable "copy picture of selected area to the clipboard" (ctrl + cmd + shift + 4)
        #     "31" = { enabled = false; };
        #     # disable "screenshot and recording options" (cmd + shift + 5)
        #     "184" = { enabled = false; };
        #
        #     "64" = {
        #       enabled = false;
        #       value = {
        #         parameters = [ 32 49 1048576 ];
        #         type = "standard";
        #       };
        #     };
        #   };
        # };
      };

      NSGlobalDomain = {
        # May be useful, need to confirm first.
        # NSDisableAutomaticTermination          = true;
        AppleEnableMouseSwipeNavigateWithScrolls = true;
        AppleEnableSwipeNavigateWithScrolls      = true;
        AppleFontSmoothing                       = 2;
        AppleICUForce24HourTime                  = true;
        AppleIconAppearanceTheme                 = "RegularDark";
        AppleInterfaceStyle                      = "Dark";
        AppleInterfaceStyleSwitchesAutomatically = true;
        AppleMeasurementUnits                    = "Centimeters";
        AppleMetricUnits                         = 1;
        ApplePressAndHoldEnabled                 = false; # Disable press-and-hold for keys in favor of key repeat
        AppleScrollerPagingBehavior              = true; # jump to the clicked section when clicked on scrollbar
        AppleShowAllExtensions                   = true;
        AppleShowScrollBars                      = "WhenScrolling";
        AppleTemperatureUnit                     = "Celsius";
        InitialKeyRepeat                         = 15;
        KeyRepeat                                = 2; # faster key repeat
        NSAutomaticCapitalizationEnabled         = false;
        NSAutomaticDashSubstitutionEnabled       = false;
        NSAutomaticInlinePredictionEnabled       = false;
        NSAutomaticPeriodSubstitutionEnabled     = false;
        NSAutomaticQuoteSubstitutionEnabled      = false;
        NSAutomaticSpellingCorrectionEnabled     = false;
        NSDocumentSaveNewDocumentsToCloud        = false;
        NSNavPanelExpandedStateForSaveMode       = true; # always use the expanded save panel
        NSNavPanelExpandedStateForSaveMode2      = true; # always use the expanded save panel
        NSScrollAnimationEnabled                 = true; # enable smooth scrolling
        _HIHideMenuBar                           = true;

        # Enable keyboard navigation.
        # 3 allows Tab key navigation through all UI elements
        # including buttons, checkboxes, and other controls in
        # dialogs.
        AppleKeyboardUIMode                      = 3;
      };

      WindowManager = {
        EnableStandardClickToShowDesktop = false; # clicking the desktop will not put the windows out of the way
        # StandardHideDesktopIcons=true; # hide icons on desktop
      };

      # hitoolbox.AppleFnUsageType = "Do Nothing"; # fn key does nothing.
      SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false; # disable automatic software updates
      spaces.spans-displays = false; # displays have seperate spaces = true (its counter-intuitive)

    };


    # Disable Spotlight metadata collection.
    system.activationScripts.disableSpotlight.text = ''
      mdutil -i off -d /
      mdutil -E /
    '';

    # services = {
    #   skhd.enable = true;
    # };

    # system.activationScripts.postActivation.text = ''
    #   echo "Purging .DS_Store files from configuration tree..."
    #   find /Users/hadal84/nix-darwin -name ".DS_Store" -type f -delete
    # '';

    # system.activationScripts.afterActivation.text = ''
    #   # Following line should allow us to avoid a logout/login cycle
    #   sudo /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    # '';

    system.keyboard = {
      enableKeyMapping = true;  # enable key mapping so that we can use `option` as `control`

      # NOTE: do NOT support remap capslock to both control and escape at the same time
      remapCapsLockToControl = false;  # remap caps lock to control, useful for emac users
      remapCapsLockToEscape  = true;   # remap caps lock to escape, useful for vim users

      # # swap left command and left alt
      # # so it matches common keyboard layout: `ctrl | command | alt`
      # #
      # # disabled, caused only problems!
      # swapLeftCommandAndLeftAlt = false;
    };

    # programs.bash.initExtra = lib.mkAfter ''
    #   if [ "$(ulimit -n)" -lt 10240 ]; then
    #     ulimit -n 65536 2>/dev/null || ulimit -n 10240
    #   fi
    # '';

    launchd.daemons.sysctl-max-files = {
      serviceConfig = {
        Label = "org.nixos.sysctl-limits";
        ProgramArguments = [
          "/bin/sh"
          "-c"
          "/usr/sbin/sysctl -w kern.maxfiles=1048576 kern.maxfilesperproc=524288 && /bin/launchctl limit maxfiles 65536 524288 && /bin/launchctl limit maxproc 65536 524288"
        ];
        RunAtLoad = true;
      };
    };

    launchd.daemons.mount-tmp-as-tmpfs = {
      serviceConfig = {
        Label = "org.nixos.mount-tmp-as-tmpfs";
        ProgramArguments = [
          "mount_tmpfs"
          "-e" # case-sensitive filesystem
          "-s"
          "10g"
          "/private/tmp"
        ];
        RunAtLoad = true;
      };
    };

    # launchd.daemons.llm-sandbox-pf = {
    #   script = ''
    #     /sbin/pfctl -q -a ${anchor} -f ${rules}
    #     /sbin/pfctl -q -E
    #     '';
    #   serviceConfig = {
    #     RunAtLoad = true;
    #     StandardErrorPath = "/var/log/llm-sandbox-pf.log";
    #     StandardOutPath = "/var/log/llm-sandbox-pf.log";
    #   };
    # };

    # # Keys without a dot become `local.<key>` in launchd; keys with a dot become
    # # `org.nixos.<key>`. Keep keys dot-free so the generated label matches
    # # `services.json` (which expects `local.litellm`/`local.ollama`).
    # launchd.daemons."litellm" = {
    #   serviceConfig = {
    #     # Explicit label to match services.json (which expects local.litellm).
    #     # Without this, nix-darwin auto-generates org.nixos.litellm.
    #     Label = "local.litellm";
    #     # macOS 26+ SIP blocks unsigned Nix store binaries for system daemons
    #     # with non-root UserName (EX_CONFIG 78). /bin/sh is Apple-signed and
    #     # ref: macos-service-hardening.instructions.md -- SIP /bin/sh wrapper
    #     ProgramArguments = [
    #       "/bin/sh"
    #       "-c"
    #       "exec ${litellmDaemon}/bin/nucleus-litellm-daemon '${litellmConfig}' '60' ${
    #         lib.concatStringsSep " " (map (arg: "'${arg}'") keyArgs)
    #       }"
    #     ];
    #     KeepAlive = true;
    #     RunAtLoad = true;
    #     UserName = username;
    #     EnvironmentVariables = litellmEnv;
    #     StandardOutPath = "${config.nucleus.logging.systemLogDir}/litellm/stdout.log";
    #     StandardErrorPath = "${config.nucleus.logging.systemLogDir}/litellm/stderr.log";
    #   };
    # };
    #
    # launchd.daemons."ollama" = {
    #   serviceConfig = {
    #     # Explicit label to match services.json (which expects local.ollama).
    #     Label = "local.ollama";
    #     # macOS 26+ SIP blocks unsigned Nix store binaries for system daemons
    #     # with non-root UserName (EX_CONFIG 78). /bin/sh is Apple-signed and
    #     # ref: macos-service-hardening.instructions.md -- SIP /bin/sh wrapper
    #     ProgramArguments = [
    #       "/bin/sh"
    #       "-c"
    #       "exec ${pkgs.ollama}/bin/ollama serve"
    #     ];
    #     KeepAlive = true;
    #     RunAtLoad = true;
    #     UserName = username;
    #     # Source: src/modules/lib/env-catalog.nix (OLLAMA_* entries).
    #     # The catalog is the single source of truth for these values.  OLLAMA_HOST
    #     # is excluded so the daemon binds to the default port (11434).  OLLAMA_HOST
    #     # is set by the gui-env LaunchAgent for CLI clients.
    #     EnvironmentVariables = ollamaEnv;
    #     StandardOutPath = "${config.nucleus.logging.systemLogDir}/ollama/stdout.log";
    #     StandardErrorPath = "${config.nucleus.logging.systemLogDir}/ollama/stderr.log";
    #   };
    # };




    # # Fully declarative dock using the latest from Nix Store
    # local = {
    #   dock.enable = true;
    #   dock.entries = [
    #     { path = "/Applications/Slack.app/"; }
    #     { path = "/System/Applications/Messages.app/"; }
    #     { path = "/System/Applications/Facetime.app/"; }
    #     { path = "/Applications/Telegram.app/"; }
    #     { path = "${pkgs.alacritty}/Applications/Alacritty.app/"; }
    #     { path = "/System/Applications/Music.app/"; }
    #     { path = "/System/Applications/News.app/"; }
    #     { path = "/System/Applications/Photos.app/"; }
    #     { path = "/System/Applications/Photo Booth.app/"; }
    #     { path = "/System/Applications/TV.app/"; }
    #     { path = "${pkgs.jetbrains.phpstorm}/Applications/PhpStorm.app/"; }
    #     { path = "/Applications/TablePlus.app/"; }
    #     { path = "/Applications/Asana.app/"; }
    #     { path = "/Applications/Drafts.app/"; }
    #     { path = "/System/Applications/Home.app/"; }
    #     { path = "/Applications/iPhone Mirroring.app/"; }
    #     {
    #       path = toString myEmacsLauncher;
    #       section = "others";
    #     }
    #     {
    #       path = "${config.users.users.${user}.home}/.local/share/";
    #       section = "others";
    #       options = "--sort name --view grid --display folder";
    #     }
    #     {
    #       path = "${config.users.users.${user}.home}/.local/share/downloads";
    #       section = "others";
    #       options = "--sort name --view grid --display stack";
    #     }
    #   ];
    # };

    # dock.nix
    # { config, pkgs, lib, ... }:
    #
    # # Original source: https://gist.github.com/antifuchs/10138c4d838a63c0a05e725ccd7bccdd
    #
    # with lib;
    # let
    #   cfg = config.local.dock;
    #   inherit (pkgs) stdenv dockutil;
    # in
    # {
    #   options = {
    #     local.dock.enable = mkOption {
    #       description = "Enable dock";
    #       default = stdenv.isDarwin;
    #       example = false;
    #     };
    #
    #     local.dock.entries = mkOption
    #       {
    #         description = "Entries on the Dock";
    #         type = with types; listOf (submodule {
    #           options = {
    #             path = lib.mkOption { type = str; };
    #             section = lib.mkOption {
    #               type = str;
    #               default = "apps";
    #             };
    #             options = lib.mkOption {
    #               type = str;
    #               default = "";
    #             };
    #           };
    #         });
    #         readOnly = true;
    #       };
    #   };
    #
    #   config =
    #     mkIf cfg.enable
    #       (
    #         let
    #           normalize = path: if hasSuffix ".app" path then path + "/" else path;
    #           entryURI = path: "file://" + (builtins.replaceStrings
    #             [" "   "!"   "\""  "#"   "$"   "%"   "&"   "'"   "("   ")"]
    #             ["%20" "%21" "%22" "%23" "%24" "%25" "%26" "%27" "%28" "%29"]
    #             (normalize path)
    #           );
    #           wantURIs = concatMapStrings
    #             (entry: "${entryURI entry.path}\n")
    #             cfg.entries;
    #           createEntries = concatMapStrings
    #             (entry: "${dockutil}/bin/dockutil --no-restart --add '${entry.path}' --section ${entry.section} ${entry.options}\n")
    #             cfg.entries;
    #         in
    #         {
    #           system.activationScripts.postUserActivation.text = ''
    #             echo >&2 "Setting up the Dock..."
    #             haveURIs="$(${dockutil}/bin/dockutil --list | ${pkgs.coreutils}/bin/cut -f2)"
    #             if ! diff -wu <(echo -n "$haveURIs") <(echo -n '${wantURIs}') >&2 ; then
    #               echo >&2 "Resetting Dock."
    #               ${dockutil}/bin/dockutil --no-restart --remove all
    #               ${createEntries}
    #               killall Dock
    #             else
    #               echo >&2 "Dock setup complete."
    #             fi
    #           '';
    #         }
    #       );
    # }


    # system = {
    #   defaults = {
    #     # menuExtraClock.Show24Hour = true;  # show 24 hour clock
    #
    #     # customize dock
    #     dock = {
    #       autohide = true;
    #       show-recents = false;  # disable recent apps
    #
    #       # customize Hot Corners(触发角, 鼠标移动到屏幕角落时触发的动作)
    #       wvous-tl-corner = 2;  # top-left - Mission Control
    #       wvous-tr-corner = 13;  # top-right - Lock Screen
    #       wvous-bl-corner = 3;  # bottom-left - Application Windows
    #       wvous-br-corner = 4;  # bottom-right - Desktop
    #     };
    #
    #     # customize finder
    #     finder = {
    #       _FXShowPosixPathInTitle = true;  # show full path in finder title
    #       AppleShowAllExtensions = true;  # show all file extensions
    #       FXEnableExtensionChangeWarning = false;  # disable warning when changing file extension
    #       QuitMenuItem = true;  # enable quit menu item
    #       ShowPathbar = true;  # show path bar
    #       ShowStatusBar = true;  # show status bar
    #     };
    #
    #     # customize trackpad
    #     trackpad = {
    #       # tap - 轻触触摸板, click - 点击触摸板
    #       Clicking = true;  # enable tap to click(轻触触摸板相当于点击)
    #       TrackpadRightClick = true;  # enable two finger right click
    #       TrackpadThreeFingerDrag = true;  # enable three finger drag
    #     };
    #
    #     # customize settings that not supported by nix-darwin directly
    #     # Incomplete list of macOS `defaults` commands :
    #     #   https://github.com/yannbertrand/macos-defaults
    #     NSGlobalDomain = {
    #       # `defaults read NSGlobalDomain "xxx"`
    #       "com.apple.swipescrolldirection" = true;  # enable natural scrolling(default to true)
    #       "com.apple.sound.beep.feedback" = 0;  # disable beep sound when pressing volume up/down key
    #       AppleInterfaceStyle = "Dark";  # dark mode
    #       AppleKeyboardUIMode = 3;  # Mode 3 enables full keyboard control.
    #       ApplePressAndHoldEnabled = true;  # enable press and hold
    #
    #       # If you press and hold certain keyboard keys when in a text area, the key’s character begins to repeat.
    #       # This is very useful for vim users, they use `hjkl` to move cursor.
    #       # sets how long it takes before it starts repeating.
    #       InitialKeyRepeat = 15;  # normal minimum is 15 (225 ms), maximum is 120 (1800 ms)
    #       # sets how fast it repeats once it starts.
    #       KeyRepeat = 3;  # normal minimum is 2 (30 ms), maximum is 120 (1800 ms)
    #
    #       NSAutomaticCapitalizationEnabled = false;  # disable auto capitalization(自动大写)
    #       NSAutomaticDashSubstitutionEnabled = false;  # disable auto dash substitution(智能破折号替换)
    #       NSAutomaticPeriodSubstitutionEnabled = false;  # disable auto period substitution(智能句号替换)
    #       NSAutomaticQuoteSubstitutionEnabled = false;  # disable auto quote substitution(智能引号替换)
    #       NSAutomaticSpellingCorrectionEnabled = false;  # disable auto spelling correction(自动拼写检查)
    #       NSNavPanelExpandedStateForSaveMode = true;  # expand save panel by default(保存文件时的路径选择/文件名输入页)
    #       NSNavPanelExpandedStateForSaveMode2 = true;
    #     };
    #
    #     # Customize settings that not supported by nix-darwin directly
    #     # see the source code of this project to get more undocumented options:
    #     #    https://github.com/rgcr/m-cli
    #     #
    #     # All custom entries can be found by running `defaults read` command.
    #     # or `defaults read xxx` to read a specific domain.
    #     CustomUserPreferences = {
    #       ".GlobalPreferences" = {
    #         # automatically switch to a new space when switching to the application
    #         AppleSpacesSwitchOnActivate = true;
    #       };
    #       NSGlobalDomain = {
    #         # Add a context menu item for showing the Web Inspector in web views
    #         WebKitDeveloperExtras = true;
    #       };
    #       "com.apple.finder" = {
    #         ShowExternalHardDrivesOnDesktop = true;
    #         ShowHardDrivesOnDesktop = true;
    #         ShowMountedServersOnDesktop = true;
    #         ShowRemovableMediaOnDesktop = true;
    #         _FXSortFoldersFirst = true;
    #         # When performing a search, search the current folder by default
    #         FXDefaultSearchScope = "SCcf";
    #       };
    #       "com.apple.desktopservices" = {
    #         # Avoid creating .DS_Store files on network or USB volumes
    #         DSDontWriteNetworkStores = true;
    #         DSDontWriteUSBStores = true;
    #       };
    #       "com.apple.spaces" = {
    #         "spans-displays" = 0; # Display have seperate spaces
    #       };
    #       "com.apple.WindowManager" = {
    #         EnableStandardClickToShowDesktop = 0; # Click wallpaper to reveal desktop
    #         StandardHideDesktopIcons = 0; # Show items on desktop
    #         HideDesktop = 0; # Do not hide items on desktop & stage manager
    #         StageManagerHideWidgets = 0;
    #         StandardHideWidgets = 0;
    #       };
    #       "com.apple.screensaver" = {
    #         # Require password immediately after sleep or screen saver begins
    #         askForPassword = 1;
    #         askForPasswordDelay = 0;
    #       };
    #       "com.apple.screencapture" = {
    #         location = "~/Desktop";
    #         type = "png";
    #       };
    #       "com.apple.AdLib" = {
    #         allowApplePersonalizedAdvertising = false;
    #       };
    #       # Prevent Photos from opening automatically when devices are plugged in
    #       "com.apple.ImageCapture".disableHotPlug = true;
    #     };
    #
    #     loginwindow = {
    #       GuestEnabled = false;  # disable guest user
    #       SHOWFULLNAME = true;  # show full name in login window
    #     };
    #   };
    #
    #   # keyboard settings is not very useful on macOS
    #   # the most important thing is to remap option key to alt key globally,
    #   # but it's not supported by macOS yet.
    #   keyboard = {
    #     enableKeyMapping = true;  # enable key mapping so that we can use `option` as `control`
    #
    #     # NOTE: do NOT support remap capslock to both control and escape at the same time
    #     remapCapsLockToControl = false;  # remap caps lock to control, useful for emac users
    #     remapCapsLockToEscape  = true;   # remap caps lock to escape, useful for vim users
    #
    #     # swap left command and left alt
    #     # so it matches common keyboard layout: `ctrl | command | alt`
    #     #
    #     # disabled, caused only problems!
    #     swapLeftCommandAndLeftAlt = false;
    #   };
    # };

  };
}
