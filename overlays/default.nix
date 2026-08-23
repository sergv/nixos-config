{
  # In configuration.nix
  ssh-overlay = _: old: {
    openssh = old.openssh.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ../patches/openssh-disable-permission-check.patch ];
      # Whether to run tests
      doCheck = false;
    });
  };

  systemd-disable-age-verification-overlay = _: old: {
    systemd = old.systemd.override {
      withUserDb   = false;
      withHomed    = false; # homed depends on userdb
      withAcl      = false;
      withApparmor = false;
      withAudit    = false;
      withTpm2Tss  = false;
    };
  };

  assert-unwanted-packages-are-not-included = _: old: {
    mariadb-server           = builtins.abort "don't want mariadb-server";
    mariadb                  = builtins.abort "don't want mariadb";
    gst-plugins-rs           = builtins.abort "don't want gst-plugins-rs";
    electron                 = builtins.abort "don't want electron";
    # gnome-settings-daemon    = builtins.abort "don't want grone-settings-daemon";
    # xdg-desktop-portal-gnome = builtins.abort "don't want xdg-desktop-portal-gnome";
    # xdg-desktop-portal-gtk   = builtins.abort "don't want xdg-desktop-portal-gtk";
  };
}
