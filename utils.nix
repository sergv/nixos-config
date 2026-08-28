let
  stdenv-use-march-optimizations =
    arch: pkgs: stdenv:
    pkgs.overrideMkDerivationArgs (args: {
      env = (args.env or { }) // {
        NIX_CFLAGS_COMPILE =
          builtins.toString (args.NIX_CFLAGS_COMPILE or "") +
          " -march=${arch} -mtune=${arch}";
      };
      preferLocalBuild = true;
      allowSubstitutes = false;
    }) stdenv;

  stdenv-disable-march-optimizations =
    arch: pkgs: stdenv:
    pkgs.overrideMkDerivationArgs (args: {
      env = (args.env or { }) // {
        NIX_CFLAGS_COMPILE =
          builtins.replaceStrings
            [ "-march=${arch}" "-mtune=${arch}" ]
            [ "" "" ]
            (builtins.toString (args.NIX_CFLAGS_COMPILE or ""));
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

  filter-bin =
    pkgs: name: keep-these: pkg:
    assert (builtins.isList keep-these);
    let
      f =
        {
          source,
          dest,
          aliases,
        }:
        assert builtins.isString source;
        assert builtins.isString dest;
        assert builtins.isList aliases && builtins.all builtins.isString aliases;
        ''
          if [[ ! -e "${pkg}/bin/${source}" ]]; then
             echo "Source file '${source}' does not exist within package ${pkg}" >&2
             exit 1
          fi
          ln -s "${pkg}/bin/${source}" "$out/bin/${dest}"
          ${builtins.concatStringsSep "\n" (
            builtins.map (a: ''ln -s "$out/bin/${dest}" "$out/bin/${a}"'') aliases
          )}
        '';
    in
    pkgs.runCommand ("filtered-" + name)
      {
        nativeBuildInputs = [ ];
      }
      ''
        mkdir -p "$out/bin"
        ${builtins.concatStringsSep "\n" (builtins.map f keep-these)}
      '';
}
