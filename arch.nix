{
  localSystem = {
    gcc.arch      = "znver4";
    gcc.tune      = "znver4";
    system        = "x86_64-linux";
  };

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
