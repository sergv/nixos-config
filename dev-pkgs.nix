args @
  { haskell-nixpkgs-improvements
  # , nixpkgs-stable
  , arch
  , system
  , pkgs
  }:
let

  lib = pkgs.lib;

  filter-bin = name: keep-these: pkg:
    assert (builtins.isList keep-these);
    let f = { source, dest, aliases }:
          assert builtins.isString source;
          assert builtins.isString dest;
          assert builtins.isList aliases && builtins.all builtins.isString aliases;
          ''
            if [[ ! -e "${pkg}/bin/${source}" ]]; then
               echo "Source file '${source}' does not exist within package ${pkg}" >&2
               exit 1
            fi
            ln -s "${pkg}/bin/${source}" "$out/bin/${dest}"
            ${builtins.concatStringsSep "\n" (builtins.map (a: ''ln -s "$out/bin/${dest}" "$out/bin/${a}"'') aliases)}
          '';
    in
      pkgs.runCommand ("filtered-" + name) {
        nativeBuildInputs = [];
      }
        ''
          mkdir -p "$out/bin"
          ${builtins.concatStringsSep "\n" (builtins.map f keep-these)}
        '';

  haskell-tools =
    let
      pkgs-haskell = pkgs.appendOverlays [ haskell-nixpkgs-improvements.overlays.host ];
      pkgs-cross-win = pkgs.appendOverlays [ haskell-nixpkgs-improvements.overlays.cross-win ];
    in
      haskell-nixpkgs-improvements.lib.derive-haskell-tools
        system
        pkgs-haskell
        pkgs-cross-win;
  all-haskell-tools =
    lib.attrsets.unionOfDisjoint
      haskell-tools.tools
      (lib.attrsets.unionOfDisjoint
        haskell-tools.ghc.host
        haskell-tools.ghc.cross-win);

in
lib.attrsets.unionOfDisjoint all-haskell-tools {

  gcc  = pkgs.gcc;
  # Conflicts with gcc regarding ld.gold
  # clang = pkgs.clang_19;
  llvm = pkgs.llvm_19;
  # bintools = pkgs.llvmPackages_19.bintools;
  # lld   = pkgs.lld_19;
  lld  = filter-bin "llvmPackages_19.bintools" [{ source = "ld"; dest = "lld"; aliases = ["ld.lld"]; }] pkgs.llvmPackages_19.bintools;

  # for ‘clang-format’
  clang-tools     = pkgs.clang-tools;
  cmake           = pkgs.cmake;
  diffutils       = pkgs.diffutils;
  gdb             = pkgs.gdb;
  gnumake         = pkgs.gnumake;
  libtree         = pkgs.libtree;
  patchelf        = pkgs.patchelf;
  pkg-config      = pkgs.pkg-config;
  universal-ctags = pkgs.universal-ctags;
}
