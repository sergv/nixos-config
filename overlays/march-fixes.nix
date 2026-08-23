# Fixes for building packages with -march=znver4
new: old: {

  # libtpms = utils.disable-march-optimizations arch-zen4 old old.libtpms;
  libtpms = old.libtpms.overrideAttrs (_: {
    doCheck = false;
  });

  rapidjson = old.rapidjson.overrideAttrs (_: {
    doCheck = false;
  });

  # Doesn’t build either way, easier to do without until I really need this.
  # frei0r = utils.disable-march-optimizations arch-zen4 old old.frei0r;
  # (old.frei0r.overrideAttrs (old: {
  #   version = "2.5.6";
  #   src = pkgs.fetchFromGitHub {
  #     owner = "dyne";
  #     repo  = "frei0r";
  #     rev   = "530f7e6388c6931f20aa2ca9e4ea33a60df7aca7";
  #     hash  = "sha256-EUFNPAAdsa96mYiCoLbD7v5PweU4atCsKh345zTDGo0=";
  #   };
  # }));

  # upower = old.upower.overrideAttrs (_: {
  #   doCheck = false;
  # });

  python313 = old.python313.override {
    packageOverrides = _: old2: {
      scipy = old2.scipy.overrideAttrs (old-attrs: {
        doCheck        = false;
        doInstallCheck = false;
      });
    };
  };
}
