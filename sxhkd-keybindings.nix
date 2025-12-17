{ wm-sh, wmctrl-pkg }:
let misc-keybindings = {
      # "super + t"          = "exo-open --launch TerminalEmulator";
      # "mod4 + t"          = "exo-open --launch TerminalEmulator";
      "mod4 + t"           = "konsole";
      # "mod4 + t"           = "xfce4-terminal";

      "KP_Divide"          = "; ${wm-sh}/bin/wm.sh backward";
      "KP_Multiply"        = "; ${wm-sh}/bin/wm.sh forward";

      # "XF86Mail"         = "; /tmp/wm_operate.py --pop";
      "mod4 + XF86Go"      = "; ${wmctrl-pkg}/bin/wmctrl -r :ACTIVE: -b toggle,fullscreen";

      # "Alt + Left"       = "; /tmp/wm_operate.py --backward";
      # "Alt + Right"      = "; /tmp/wm_operate.py --forward";
    };

    main-keybindings = [
      { cmd = "; ${wm-sh}/bin/wm.sh swap";
        keys = [
          # 0
          "KP_Insert"
          "XF86Go"
          # Prior = Page Down
          "mod4 + Prior"
          # Regular keyboards
          "Menu"
        ];
      }

      { cmd = "; ${wm-sh}/bin/wm.sh switch 0";
        keys = [
          # 1 numpad
          "KP_End"
          # Kinesis
          "mod4 + 1"
          "mod4 + F1"
        ];
      }

      { cmd = "; ${wm-sh}/bin/wm.sh switch 1";
        keys = [
          # 2 numpad
          "KP_Down"
          # Kinesis
          "mod4 + 2"
          "mod4 + F2"
        ];
      }

      { cmd = "; ${wm-sh}/bin/wm.sh switch 2";
        keys = [
          # 3 numpad
          "KP_Next"
          # Kinesis
          "mod4 + 3"
          "mod4 + F3"
        ];
      }

      { cmd = "; ${wm-sh}/bin/wm.sh switch 3";
        keys = [
          # 4 numpad
          "KP_Left"
          # Kinesis
          "mod4 + 4"
          "mod4 + F4"
        ];
      }

      { cmd = "; ${wm-sh}/bin/wm.sh switch 4";
        keys = [
          # 5 numpad
          "KP_Begin"
          # Kinesis
          "mod4 + 5"
          "mod4 + F5"
        ];
      }

      { cmd = "; ${wm-sh}/bin/wm.sh switch 5";
        keys = [
          # 6 numpad
          "KP_Right"
          # Kinesis
          "mod4 + 6"
          "mod4 + F6"
        ];
      }

      { cmd = "; ${wm-sh}/bin/wm.sh switch 6";
        keys = [
          # 7 numpad
          "KP_Home"
          # Kinesis
          "mod4 + 7"
          "mod4 + F7"
        ];
      }

      { cmd = "; ${wm-sh}/bin/wm.sh switch 7";
        keys = [
          # 8 numpad
          "KP_Up"
          # Kinesis
          "mod4 + 8"
          "mod4 + F8"
        ];
      }

      { cmd = "; ${wm-sh}/bin/wm.sh switch 9";
        keys = [
          # 9 numpad
          "KP_Prior"
          # Kinesis
          "mod4 + 9"
          "mod4 + F9"
        ];
      }

      { cmd = "; ${wm-sh}/bin/wm.sh switch 10";
        keys = [
          # Dot on numpad
          "KP_Delete"
          # Kinesis
          "mod4 + 0"
          "mod4 + F10"
        ];
      }

      { cmd = "; ${wm-sh}/bin/wm.sh move-active-to 0";
        keys = [
          # Numpad
          "shift + KP_End"
          # Kinesis
          "control + mod4 + 1"
        ];
      }

      { cmd = "; ${wm-sh}/bin/wm.sh move-active-to 1";
        keys = [
          # Numpad
          "shift + KP_Down"
          # Kinesis
          "control + mod4 + 2"
        ];
      }

      { cmd = "; ${wm-sh}/bin/wm.sh move-active-to 2";
        keys = [
          # Numpad
          "shift + KP_Next"
          # Kinesis
          "control + mod4 + 3"
        ];
      }

      { cmd = "; ${wm-sh}/bin/wm.sh move-active-to 3";
        keys = [
          # Numpad
          "shift + KP_Left"
          # Kinesis
          "control + mod4 + 4"
        ];
      }

      { cmd = "; ${wm-sh}/bin/wm.sh move-active-to 4";
        keys = [
          # Numpad
          "shift + KP_Begin"
          # Kinesis
          "control + mod4 + 5"
        ];
      }

      { cmd = "; ${wm-sh}/bin/wm.sh move-active-to 5";
        keys = [
          # Numpad
          "shift + KP_Right"
          # Kinesis
          "control + mod4 + 6"
        ];
      }

      { cmd = "; ${wm-sh}/bin/wm.sh move-active-to 6";
        keys = [
          # Numpad
          "shift + KP_Home"
          # Kinesis
          "control + mod4 + 7"
        ];
      }

      { cmd = "; ${wm-sh}/bin/wm.sh move-active-to 7";
        keys = [
          # Numpad
          "shift + KP_Up"
          # Kinesis
          "control + mod4 + 8"
        ];
      }

      { cmd = "; ${wm-sh}/bin/wm.sh move-active-to 9";
        keys = [
          # Numpad
          "shift + KP_Prior"
          # Kinesis
          "control + mod4 + 9"
        ];
      }

      { cmd = "; ${wm-sh}/bin/wm.sh move-active-to 10";
        keys = [
          # Numpad
          "shift + KP_Delete"
          # Kinesis
          "control + mod4 + 0"
        ];
      }
    ];
in
builtins.foldl'
  (acc: { cmd, keys }:
    builtins.foldl'
      (acc2: key: { "${key}" = cmd; } // acc2)
      acc
      keys)
  misc-keybindings
  main-keybindings
