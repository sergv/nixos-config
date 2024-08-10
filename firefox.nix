{ pkgs, firefox-addons }:

let addons = firefox-addons;

    # mk-addon = id: pkg:
    #   "{531906d3-e22f-4a6c-a102-8057b88a1a63}" = {
    #     # NoScript
    #     install_url = "file:///${addons.single-file}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/{531906d3-e22f-4a6c-a102-8057b88a1a63}.xpi";
    #     installation_mode = "force_installed";
    #   };

in {
  # package = pkgs.firefox;
  enable = true;

  package = pkgs.wrapFirefox pkgs.firefox-esr-unwrapped {
    nativeMessagingHosts = [ pkgs.vdhcoapp ];
  };

  # Refer to https://mozilla.github.io/policy-templates or `about:policies#documentation` in firefox
  policies = {
    AppAutoUpdate = false; # Disable automatic application update
    BackgroundAppUpdate = false; # Disable automatic application update in the background, when the application is not running.
    DisableBuiltinPDFViewer = true; # Considered a security liability
    DisableFirefoxStudies = true;
    DisableFirefoxAccounts = true; # Disable Firefox Sync
    DisableFirefoxScreenshots = true; # No screenshots?
    DisableForgetButton = true; # Thing that can wipe history for X time, handled differently
    DisableMasterPasswordCreation = true; # To be determined how to handle master password
    DisableProfileImport = true; # Purity enforcement: Only allow nix-defined profiles
    DisableProfileRefresh = true; # Disable the Refresh Firefox button on about:support and support.mozilla.org
    DisableSetDesktopBackground = true; # Remove the “Set As Desktop Background…” menuitem when right clicking on an image, because Nix is the only thing that can manage the backgroud
    DisplayMenuBar = "default-off";
    DisablePocket = true;
    DisableTelemetry = true;
    DisableFormHistory = true;
    DisablePasswordReveal = true;
    DontCheckDefaultBrowser = true;
    HardwareAcceleration = false; # Disabled as it's exposes points for fingerprinting
    OfferToSaveLogins = false; # Managed by KeepAss instead
    EnableTrackingProtection = {
      Value          = true;
      Locked         = true;
      Cryptomining   = true;
      Fingerprinting = true;
      EmailTracking  = true;
      # Exceptions = ["https://example.com"]
    };
    EncryptedMediaExtensions = {
      Enabled = true;
      Locked  = true;
    };
    ExtensionUpdate = false;

    # FIXME(Krey): Review `~/.mozilla/firefox/Default/extensions.json` and uninstall all unwanted
    # Suggested by t0b0 thank you <3 https://gitlab.com/engmark/root/-/blob/60468eb82572d9a663b58498ce08fafbe545b808/configuration.nix#L293-310
    # NOTE(Krey): Check if the addon is packaged on https://gitlab.com/rycee/nur-expressions/-/blob/master/pkgs/firefox-addons/addons.json

    # More at https://gitlab.com/rycee/nur-expressions/-/blob/master/pkgs/firefox-addons/addons.json?ref_type=heads
    ExtensionSettings = {
      "*" = {
        installation_mode = "blocked";
        blocked_install_message = "Don't install extra extensions here, add them to nix derivation instead";
      };

      # Dark Reader
      "addon@darkreader.org" = {
        install_url = "file:///${addons.darkreader}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/addon@darkreader.org.xpi";
        installation_mode = "force_installed";
      };

      # NoScript
      "{73a6fe31-595d-460b-a920-fcc0f8843232}" = {
        install_url = "file:///${addons.noscript}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/{73a6fe31-595d-460b-a920-fcc0f8843232}.xpi";
        installation_mode = "force_installed";
      };

      # Return youtube dislike
      "{762f9885-5a13-4abd-9c77-433dcd38b8fd}" = {
        # NoScript
        install_url = "file:///${addons.return-youtube-dislikes}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/{762f9885-5a13-4abd-9c77-433dcd38b8fd}.xpi";
        installation_mode = "force_installed";
      };

      "jid1-KKzOGWgsW3Ao4Q@jetpack" = {
        # NoScript
        install_url = "file:///${addons.i-dont-care-about-cookies}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/jid1-KKzOGWgsW3Ao4Q@jetpack.xpi";
        installation_mode = "force_installed";
      };

      # Leechblock
      "leechblockng@proginosko.com" = {
        # NoScript
        install_url = "file:///${addons.leechblock-ng}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/leechblockng@proginosko.com.xpi";
        installation_mode = "force_installed";
      };

      # Video Download helper
      "{b9db16a4-6edc-47ec-a1f4-b86292ed211d}" = {
        # NoScript
        install_url = "file:///${addons.video-downloadhelper}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/{b9db16a4-6edc-47ec-a1f4-b86292ed211d}.xpi";
        installation_mode = "force_installed";
      };

      # SingleFile
      "{531906d3-e22f-4a6c-a102-8057b88a1a63}" = {
        # NoScript
        install_url = "file:///${addons.single-file}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/{531906d3-e22f-4a6c-a102-8057b88a1a63}.xpi";
        installation_mode = "force_installed";
      };

      # uBlock Origin
      "uBlock0@raymondhill.net" = {
        # uBlock Origin
        # install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        install_url = "file:///${addons.ublock-origin}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/uBlock0@raymondhill.net.xpi";
        installation_mode = "force_installed";
      };

      # Privacy Badger
      "jid1-MnnxcxisBPnSXQ@jetpack" = {
        install_url = "file:///${addons.privacy-badger}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/jid1-MnnxcxisBPnSXQ@jetpack.xpi";
        installation_mode = "force_installed";
      };

      # Consent-o-Matic
      "gdpr@cavi.au.dk" = {
        install_url = "file:///${addons.consent-o-matic}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/gdpr@cavi.au.dk.xpi";
        installation_mode = "force_installed";
      };


      # VK music downloader
      "{a8fff5e8-00c2-455a-9958-d8cd10f8206d}" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/file/4118483/vkd-1.7.73.xpi";
        installation_mode = "force_installed";
      };

      # Tab control
      "{407e597e-40d5-4fdb-9847-4a52830e7e65}" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/file/4274623/tab_control-2.3resigned1.xpi";
        installation_mode = "force_installed";
      };

      # Group Speed Dial
      "admin@fastaddons.com_GroupSpeedDial" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/file/4282580/groupspeeddial-25.2.xpi";
        installation_mode = "force_installed";
      };

      # Remove YouTube Recommends
      "kunal@abhashtech.com" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/file/4275238/remove_youtube_recomendation-0.3resigned1.xpi";
        installation_mode = "force_installed";
      };

      # No YouTube comments
      "jid1-YMBCq41qvDdqcA@jetpack" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/file/4270539/no_youtube_comments-0.4resigned1.xpi";
        installation_mode = "force_installed";
      };

      # RYS — Remove YouTube Suggestions
      "{21f1ba12-47e1-4a9b-ad4e-3a0260bbeb26}" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/file/4299785/remove_youtube_s_suggestions-4.3.60.xpi";
        installation_mode = "force_installed";
      };

      # "7esoorv3@alefvanoon.anonaddy.me" = {
      # # LibRedirect
      # install_url = "file:///${addons.libredirect}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/7esoorv3@alefvanoon.anonaddy.me.xpi";
      # installation_mode = "force_installed";
      # };
      # "jid0-3GUEt1r69sQNSrca5p8kx9Ezc3U@jetpack" = {
      #   # Terms of Service, Didn't Read
      #   install_url = "file:///${addons.terms-of-service-didnt-read}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/jid0-3GUEt1r69sQNSrca5p8kx9Ezc3U@jetpack.xpi";
      #   installation_mode = "force_installed";
      # };
      # "keepassxc-browser@keepassxc.org" = {
      #   # KeepAssXC-Browser
      #   install_url = "file:///${addons.keepassxc-browser}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/keepassxc-browser@keepassxc.org.xpi";
      #   installation_mode = "force_installed";
      # };
      # # FIXME(Krey): Contribute this in NUR
      # "dont-track-me-google@robwu.nl" = {
      #   # Don't Track Me Google
      #   install_url = "https://addons.mozilla.org/firefox/downloads/latest/dont-track-me-google1/latest.xpi";
      #   installation_mode = "force_installed";
      # };
      # "jid1-BoFifL9Vbdl2zQ@jetpack" = {
      #   # Decentrayeles
      #   install_url = "file:///${addons.decentraleyes}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/jid1-BoFifL9Vbdl2zQ@jetpack.xpi";
      #   installation_mode = "force_installed";
      # };
      # "{74145f27-f039-47ce-a470-a662b129930a}" = {
      #   # ClearURLs
      #   install_url = "file:///${addons.clearurls}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/{74145f27-f039-47ce-a470-a662b129930a}.xpi";
      #   installation_mode = "force_installed";
      # };
      # "sponsorBlocker@ajay.app" = {
      #   # Sponsor Block
      #   install_url = "file:///${addons.sponsorblock}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/sponsorBlocker@ajay.app.xpi";
      #   installation_mode = "force_installed";
      # };
      # "jid1-MnnxcxisBPnSXQ@jetpack" = {
      #   # Privacy Badger
      #   install_url = "file:///${addons.privacy-badger}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/jid1-MnnxcxisBPnSXQ@jetpack.xpi";
      #   installation_mode = "force_installed";
      # };
      # "uBlock0@raymondhill.net" = {
      #   # uBlock Origin
      #   install_url = "file:///${addons.ublock-origin}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/uBlock0@raymondhill.net.xpi";
      #   installation_mode = "force_installed";
      # };
    };

    "3rdparty".Extensions = {
      # # https://github.com/libredirect/browser_extension/blob/b3457faf1bdcca0b17872e30b379a7ae55bc8fd0/src/config.json
      # "7esoorv3@alefvanoon.anonaddy.me" = {
      # # FIXME(Krey): This doesn't work
      # services.youtube.options.enabled = true;
      # };
      # https://github.com/gorhill/uBlock/blob/master/platform/common/managed_storage.json
      "uBlock0@raymondhill.net".adminSettings = {
        userSettings = rec {
          uiTheme = "dark";
          uiAccentCustom = true;
          uiAccentCustom0 = "#8300ff";
          cloudStorageEnabled = pkgs.lib.mkForce false; # Security liability?
          importedLists = [
            "https://filters.adtidy.org/extension/ublock/filters/3.txt"
            "https://github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
          ];
          externalLists = pkgs.lib.concatStringsSep "\n" importedLists;
        };
        selectedFilterLists = [
          "RUS-0"
          "adguard-annoyance"
          "adguard-cookies"
          "adguard-generic"
          "adguard-popup-overlays"
          "adguard-social"
          "adguard-spyware"
          "adguard-spyware-url"
          "adguard-widgets"
          "block-lan"
          "curben-phishing"
          "dpollock-0"
          "easylist"
          "easylist-annoyances"
          "easylist-chat"
          "easylist-newsletters"
          "easylist-notifications"
          "easyprivacy"
          "fanboy-cookiemonster"
          "fanboy-social"
          "fanboy-thirdparty_social"
          "https://github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
          "plowe-0"
          "ublock-abuse"
          "ublock-annoyances"
          "ublock-badware"
          "ublock-cookies-adguard"
          "ublock-cookies-easylist"
          "ublock-filters"
          "ublock-privacy"
          "ublock-quick-fixes"
          "ublock-unbreak"
          "urlhaus-1"
          # Enable my custom filtering rules from "userFilters".
          "user-filters"
        ];
        userFilters =
          pkgs.lib.concatStringsSep "\n" [
            # https://www.youtube.com Remove annoying logo that may have animations, I hate them real bad now
            "www.youtube.com##ytd-yoodle-renderer.ytd-topbar-logo-renderer.style-scope"
          ];
      };
    };

    FirefoxHome = {
      Search = true;
      TopSites = true;
      SponsoredTopSites = false; # Go away
      Highlights = true;
      Pocket = false;
      SponsoredPocket = false; # Go away
      Snippets = false;
      Locked = true;
    };
    FirefoxSuggest = {
      WebSuggestions = false;
      SponsoredSuggestions = false; # Go away
      ImproveSuggest = false;
      Locked = true;
    };
    Handlers = {
      # FIXME-QA(Krey): Should be openned in evince if on GNOME
      mimeTypes."application/pdf".action = "saveToDisk";
      schemes.mailto.handlers = [
        null
      ];
    };
    # extensions = {
    # pdf = {
    # action = "useHelperApp";
    # ask = true;
    # # FIXME-QA(Krey): Should only happen on GNOME
    # handlers = [
    # {
    #   name = "GNOME Document Viewer";
    #   path = "${pkgs.evince}/bin/evince";
    # }
    # ];
    # };
    # };
    NoDefaultBookmarks = true;
    PasswordManagerEnabled = false; # Managed by KeepAss
    PDFjs = {
      Enabled = false; # Go away now
      EnablePermissions = false;
    };
    # Permissions = {
    #   Camera = {
    #     Allow = [https =//example.org,https =//example.org =1234];
    #     Block = [https =//example.edu];
    #     BlockNewRequests = true;
    #     Locked = true
    #   };
    #   Microphone = {
    #     Allow = [https =//example.org];
    #     Block = [https =//example.edu];
    #     BlockNewRequests = true;
    #     Locked = true
    #   };
    #   Location = {
    #     Allow = [https =//example.org];
    #     Block = [https =//example.edu];
    #     BlockNewRequests = true;
    #     Locked = true
    #   };
    #   Notifications = {
    #     Allow = [https =//example.org];
    #     Block = [https =//example.edu];
    #     BlockNewRequests = true;
    #     Locked = true
    #   };
    #   Autoplay = {
    #     Allow = [https =//example.org];
    #     Block = [https =//example.edu];
    #     Default = allow-audio-video | block-audio | block-audio-video;
    #     Locked = true
    #   };
    # };
    PictureInPicture = {
      Enabled = true;
      Locked = true;
    };
    PromptForDownloadLocation = true;
    Proxy = {
      Mode = "none"; # "manual"; # none | system | manual | autoDetect | autoConfig;
      Locked = false;
      # HTTPProxy = hostname;
      # UseHTTPProxyForAllProtocols = true;
      # SSLProxy = hostname;
      # FTPProxy = hostname;
      SOCKSProxy = "127.0.0.1:9050"; # Tor
      SOCKSVersion = 5; # 4 | 5
      #Passthrough = <local>;
      # AutoConfigURL = URL_TO_AUTOCONFIG;
      # AutoLogin = true;
      UseProxyForDNS = true;
    };
    SanitizeOnShutdown = {
      Cache = true;
      Cookies = false;
      Downloads = true;
      FormData = true;
      History = false;
      Sessions = false;
      SiteSettings = false;
      OfflineApps = true;
      Locked = true;
    };
    SearchEngines = {
      PreventInstalls = true;
      # Add = [
      #   {
      #     Name = "SearXNG";
      #     URLTemplate = "http://searx3aolosaf3urwnhpynlhuokqsgz47si4pzz5hvb7uuzyjncl2tid.onion/search?q={searchTerms}";
      #     Method = "GET"; # GET | POST
      #     IconURL = "http://searx3aolosaf3urwnhpynlhuokqsgz47si4pzz5hvb7uuzyjncl2tid.onion/favicon.ico";
      #     # Alias = example;
      #     Description = "SearX instance ran by tiekoetter.com as onion-service";
      #     #PostData = name=value&q={searchTerms};
      #     #SuggestURLTemplate = https =//www.example.org/suggestions/q={searchTerms}
      #   }
      # ];
      Remove = [
        "Amazon.com" # Go away
        "Bing" # Go away
        "Google" # Go away now
      ];
      Default = "SearXNG";
    };
    SearchSuggestEnabled = false;
    ShowHomeButton = true;
    # FIXME-SECURITY(Krey): Decide what to do with this
    # SSLVersionMax = tls1 | tls1.1 | tls1.2 | tls1.3;
    # SSLVersionMin = tls1 | tls1.1 | tls1.2 | tls1.3;
    # SupportMenu = {
    #   Title = Support Menu;
    #   URL = http =//example.com/support;
    #   AccessKey = S
    # };
    StartDownloadsInTempDirectory = true;
    UserMessaging = {
      ExtensionRecommendations = false; # Don’t recommend extensions while the user is visiting web pages
      FeatureRecommendations = false; # Don’t recommend browser features
      Locked = true; # Prevent the user from changing user messaging preferences
      MoreFromMozilla = false; # Don’t show the “More from Mozilla” section in Preferences
      SkipOnboarding = true; # Don’t show onboarding messages on the new tab page
      UrlbarInterventions = false; # Don’t offer suggestions in the URL bar
      WhatsNew = false; # Remove the “What’s New” icon and menuitem
    };
    UseSystemPrintDialog = true;
    # WebsiteFilter = {
    #   Block = [<all_urls>];
    #   Exceptions = [http =//example.org/*]
    # };
  };

  arkenfox = {
    enable = true; # Decide how we want to handle these things
    version = "115.1"; # Used on 119.0, because we don't have firefox 118.0 handy
  };

  profiles.Default = {
    # programs.firefox.profiles.<name>.userContent
    #
    #     Custom Firefox user content CSS.
    #     Type: strings concatenated with “\n”
    #     Default: ""
    #     Example:
    #     ''
    #       /* Hide scrollbar in FF Quantum */
    #       *{scrollbar-width:none !important}
    #     ''

    isDefault = true;

    # Documentation https://arkenfox.dwarfmaster.net
    arkenfox = {
      enable = true;

      # STARTUP
      "0100" = {
        enable = false;
        "0105".enable = true; # Disable sponsored content on Firefox Home (Activity Stream)
        "0106".enable = true; # Clear default topsites
      };

      "0200" = {
        enable = false;
        # GEOLOCATION / LANGUAGE / LOCALE
        "0201".enable = true; # Use Mozilla geolocation service instead of Google if permission is granted [FF74+]
        "0202".enable = true; # Disable using the OS's geolocation service
        # "0203".enable = true; # disable region updates
        # WARNING(Krey): May break some input methods e.g xim/ibus for CJK languages [1]
        "0211".enable = true; # Use en-US locale regardless of the system or region locale
      };

      # QUIETER FOX (Handles telemetry, etc..)
      "0300" = {
        enable = true;
      };

      # BLOCK IMPLICIT OUTBOUND [not explicitly asked for - e.g. clicked on]
      "0600" = {
        enable = true;
      };

      "0700" = {
        enable = false;
        "0704".enable = true; # Disable GIO as a potential proxy bypass vector
      };

      "0800" = {
        enable = false;
        # LOCATION BAR / SEARCH BAR / SUGGESTIONS / HISTORY / FORMS
        "0802".enable = true; # disable location bar domain guessing
        "0804".enable = true; # disable live search suggestions
        "0805".enable = true; # disable location bar making speculative connections
        "0806".enable = true; # disable location bar leaking single words to a DNS provider **after searching**
        "0807".enable = true; # disable location bar contextual suggestions
        "0820".enable = true; # disable coloring of visited links
      };

      # PASSWORDS
      "0900" = {
        enable = true;
      };

      # HTTPS (SSL/TLS / OCSP / CERTS / HPKP)
      "1200" = {
        enable = true;
      };

      # FONTS
      "1400" = {
        enable = true;
      };

      # HEADERS ? REFERERS
      "1600" = {
        enable = true;
      };

      # CONTAINERS
      "1700" = {
        enable = true;
      };

      # PLUGINS / MEDIA / WEBRTC
      "2000" = {
        enable = false;
        "2002".enable = true; # Force WebRTC inside the proxy [FF70+]
        "2003".enable = true; # Force a single network interface for ICE candidates generation [FF42+]
        "2004".enable = true; # Force exclusion of private IPs from ICE candidates [FF51+]
        "2020".enable = true; # Disable GMP (Gecko Media Plugins) - https://wiki.mozilla.org/GeckoMediaPlugins
        # "2030".enable = true; # Disable autoplay of HTML5 media
        # "2031".enable = true; # Disable autoplay of HTML5 media if you interacted with the site
      };

      # DOM (DOCUMENT OBJECT MODEL)
      # Prevent scrips from resizing open windows (could be used for fingerprinting)
      "2400" = {
        enable = true;
      };

      "2600" = {
        enable = false;
        # MISCELLANEOUS
        "2601".enable = true; # Prevent accessibility services from accessing your browser
        "2603".enable = true; # Remove temp files opened with an external application on exit
        "2606".enable = true; # Disable UITour backend so there is no chance that a remote page can use it
        "2608".enable = true; # Reset remote debugging to disabled
        "2615".enable = true; # Disable websites overriding Firefox's keyboard shortcuts [FF58+]
        "2616".enable = true; # Remove special permissions for certain mozilla domains [FF35+]
        "2617".enable = true; # Remove webchannel whitelist (Seems to be deprecated with mozilla having still permissions in it)
        "2619".enable = true; # Use Punycode in Internationalized Domain Names to eliminate possible spoofing
        "2620".enable = true; # Enforce PDFJS, disable PDFJS scripting
        # "2621".enable = true; # Disable links launching Windows Store on Windows 8/8.1/10 [WINDOWS]
        "2623".enable = true; # Disable permissions delegation [FF73+], Disabling delegation means any prompts for these will show/use their correct 3rd party origin
        "2624".enable = true; # Disable middle click on new tab button opening URLs or searches using clipboard [FF115+]
        "2651".enable = true; # Enable user interaction for security by always asking where to download
        "2652".enable = true; # Disable downloads panel opening on every download [FF96+]
        "2654".enable = true; # Enable user interaction for security by always asking how to handle new mimetypes [FF101+]
        "2662".enable = true; # Disable webextension restrictions on certain mozilla domains (you also need 4503) [FF60+]
      };

      # ETP (ENHANCED TRACKING PROTECTION)
      "2700" = {
        enable = true;
      };

      "2800" = {
        enable = false;
        "2811".enable = true; # Set/enforce what items to clear on shutdown (if 2810 is true)
        "2812".enable = true; # Set Session Restore to clear on shutdown (if 2810 is true) [FF34+]
        "2815".enable = true; # Set "Cookies" and "Site Data" to clear on shutdown (if 2810 is true)
      };

      # EFP (RESIST FINGERPRINTING)
      "4500" = {
        enable = true;
        # "4503".enable = true; # Disable mozAddonManager Web API [FF57+]
        "4504".enable = false; # Letterboxing
      };

      # OPTIONAL OPSEC
      "5000" = {
        enable = false;
        "5003".enable = true; # Disable saving passwords
        "5004".enable = true; # Disable permissions manager from writing to disk [FF41+] [RESTART], This means any permission changes are session only
      };

      # OPTIONAL HARDENING
      ## NOTE(Krey): There are new vulnerabilities discovered in 2023, better disable it for now
      "5500" = {
        enable = false;
        "5505".enable = true; # Diable Ion and baseline JIT to harden against JS exploits
        # user_pref("javascript.options.wasm", false);
        "5506".enable = true; # Disable WebAssembly
      };

      # DONT TOUTCH
      ## NOTE(Krey): By default arkenfox flake sets all options are set to disabled, and these are expected to be always enabled
      "6000" = {
        enable = true;
      };

      # DONT BOTHER
      "7000" = {
        enable = false;
        "7001".enable = true; # Disables Location-Aware Browsing, Full Screen Geo is behind a prompt (7002). Full screen requires user interaction
        "7003".enable = true; # Disable non-modern cipher suites
        "7004".enable = true; # Control TLS Versions, because they are used as a passive fingerprinting
        "7005".enable = true; # Disable SSL Session IDs [FF36+]
        "7006".enable = true; # Onions
        "7007".enable = true; # Referencers, only cross-origin referers (1600s) need control
        "7011".enable = true; # Disable website control over browser right-click context menu
        "7013".enable = true; # Disable Clipboard API
        "7014".enable = true; # Disable System Add-on updates (Managed by Nix)
      };

      # DON'T BOTHER: FINGERPRINTING
      "8000" = {
        enable = false;
        "8001".enable = true; # Disable APIs
      };

      # NON-PROJECT RELATED
      "9000" = {
        enable = true;
        "9002".enable = true; # Disable General>Browsing>Recommend extensions/features as you browse [FF67+]
      };
    };

    settings = {
      "network.proxy.socks_remote_dns" = true; # Do DNS lookup through proxy (required for tor to work)
      "toolkit.tabbox.switchByScrolling" = true; # Allow scrolling tabs with mouse wheel

      # Sacrifice some fingerprintability but don’t keep box around content
      # which is super annoying.
      # # Enable letterboxing
      # "privacy.resistFingerprinting.letterboxing" = true;
      "privacy.resistFingerprinting.letterboxing" = false;

      # WebGL
      "webgl.disabled" = true;

      "browser.preferences.defaultPerformanceSettings.enabled" = false;
      "layers.acceleration.disabled" = true;
      "privacy.globalprivacycontrol.enabled" = true;

      # "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;

      # "network.trr.mode" = 3;

      # "network.dns.disableIPv6" = false;

      "privacy.donottrackheader.enabled" = true;

      # "privacy.clearOnShutdown.history" = true;
      # "privacy.clearOnShutdown.downloads" = true;
      # "browser.sessionstore.resume_from_crash" = true;

      # See https://librewolf.net/docs/faq/#how-do-i-fully-prevent-autoplay for options
      "media.autoplay.blocking_policy" = 2;

      "privacy.resistFingerprinting" = true;

      # Disable IPv6 as it's potentially leaky.
      # 0701 under arkenfox.
      "network.dns.disableIPv6" = true;

      # Disable location bar using search - Don't leak URL typos to a search engine, give an error message instead
      "keyword.enabled" = false;

      # Display all parts of the url in the location bar.
      # 0803 under arkenfox.
      "browser.urlbar.trimURLs" = false;

      "browser.cache.memory.enable" = true;
      # In kibibytes.
      "browser.cache.memory.capacity" = 102400;

      # Disable all DRM content (EME: Encryption Media Extension)
      # 2022 under arkenfox.
      "media.eme.enabled" = false;

      "browser.sessionstore.max_tabs_undo" = 2;
      "browser.sessionstore.resume_from_crash" = true;

      # Disable sending additional analytics to web servers
      # 2602 under arkenfox
      "beacon.enabled" = false;

      # Disable other
      # 8002 under arkenfox
      "browser.display.use_document_fonts" = 0;
      "browser.zoom.siteSpecific"          = false;
      "dom.w3c_touch_events.enabled"       = 0;
      "media.navigator.enabled"            = false;
      "media.ondevicechange.enabled"       = false;
      "media.video_stats.enabled"          = false;
      "media.webspeech.synth.enabled"      = false;
      "webgl.enable-debug-renderer-info"   = false;
    };
  };
}

