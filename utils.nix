let
  stdenv-use-march-optimizations =
    arch: pkgs: stdenv:
    pkgs.overrideMkDerivationArgs (args: {
      env = (args.env or { }) // {
        NIX_CFLAGS_COMPILE = builtins.toString (args.NIX_CFLAGS_COMPILE or "") + " -march=${arch.gccArch}";
      };
      preferLocalBuild = true;
      allowSubstitutes = false;
    }) stdenv;

  stdenv-disable-march-optimizations =
    arch: pkgs: stdenv:
    pkgs.overrideMkDerivationArgs (args: {
      env = (args.env or { }) // {
        NIX_CFLAGS_COMPILE = builtins.replaceStrings [ "-march=${arch.gccArch}" ] [ "" ] (
          builtins.toString (args.NIX_CFLAGS_COMPILE or "")
        );
      };
      preferLocalBuild = true;
      allowSubstitutes = false;
    }) stdenv;
in
{
  use-march-optimizations =
    arch: pkgs: pkg:
    if arch == null
    then
      pkg
    else
      pkg.override (old: {
        stdenv = stdenv-use-march-optimizations arch pkgs old.stdenv;
      });

  disable-march-optimizations =
    arch: pkgs: pkg:
    if arch == null
    then
      pkg
    else
      pkg.override (old: {
        stdenv = stdenv-disable-march-optimizations arch pkgs old.stdenv;
      });
}
