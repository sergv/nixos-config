args@{
  # , nixpkgs-stable
  system,
  pkgs
}:
let

  filter-bin =
    name: keep-these: pkg:
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

in
{
  gcc = pkgs.gcc;
  # Conflicts with gcc regarding ld.gold
  # clang = pkgs.clang_22;
  llvm = pkgs.llvmPackages_22.llvm;
  # bintools = pkgs.llvmPackages_22.bintools;
  # lld   = pkgs.lld_22;
  lld = filter-bin "llvmPackages_22.bintools" [
    {
      source  = "ld";
      dest    = "lld";
      aliases = [ "ld.lld" ];
    }
  ] pkgs.llvmPackages_22.bintools;

  # for ‘clang-format’
  clang-tools     = pkgs.llvmPackages_22.clang-tools;
  cmake           = pkgs.cmake;
  diffutils       = pkgs.diffutils;
  gdb             = pkgs.gdb;
  gnumake         = pkgs.gnumake;
  libtree         = pkgs.libtree;
  patchelf        = pkgs.patchelf;
  pkg-config      = pkgs.pkg-config;
  universal-ctags = pkgs.universal-ctags;
}
