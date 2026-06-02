let

  gccArch = "znver4";

  stdenv-use-march-optimizations = pkgs: stdenv:
    pkgs.overrideMkDerivationArgs
      (args: {
        env = (args.env or {}) // {
          NIX_CFLAGS_COMPILE = builtins.toString (args.NIX_CFLAGS_COMPILE or "") + " -march=${gccArch}";
        };
        preferLocalBuild = true;
        allowSubstitutes = false;
      })
      stdenv;

  stdenv-disable-march-optimizations = pkgs: stdenv:
    pkgs.overrideMkDerivationArgs
      (args: {
        env = (args.env or {}) // {
          NIX_CFLAGS_COMPILE =
            builtins.replaceStrings
              [ "-march=${gccArch}" ]
              [ "" ]
              (builtins.toString (args.NIX_CFLAGS_COMPILE or ""));
        };
        preferLocalBuild = true;
        allowSubstitutes = false;
      })
      stdenv;

in {
  localSystem = {
    gcc.arch      = "znver4";
    gcc.tune      = "znver4";
    system        = "x86_64-linux";
  };

  inherit gccArch;

  use-march-optimizations = pkgs: pkg:
    pkg.override (old: {
      stdenv = stdenv-use-march-optimizations pkgs old.stdenv;
    });

  disable-march-optimizations = pkgs: pkg:
    pkg.override (old: {
      stdenv = stdenv-disable-march-optimizations pkgs old.stdenv;
    });

  # replaceStdenv = { pkgs }: pkgs.stdenv;
    # pkgs.gcc12Stdenv;
    #
    # pkgs.clangStdenv;
    # # pkgs.gcc13Stdenv;
    # pkgs.overrideCC pkgs.stdenv
    #   (pkgs.wrapNonDeterministicGcc
    #     pkgs.stdenv
    #     # pkgs.gcc_latest
    #     pkgs.gcc13);

  # replaceStdenv = { pkgs }:
  #   # pkgs.gcc13Stdenv;
  #   pkgs.overrideCC pkgs.stdenv
  #     (pkgs.wrapNonDeterministicGcc
  #       pkgs.stdenv
  #       # pkgs.gcc_latest
  #       pkgs.gcc13);
}
