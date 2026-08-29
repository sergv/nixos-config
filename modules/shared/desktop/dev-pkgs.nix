{ lib, pkgs, sergv }:
{
  gcc = pkgs.gcc;
  # Conflicts with gcc regarding ld.gold
  # clang = pkgs.clang_22;
  llvm = pkgs.llvmPackages_22.llvm;
  # bintools = pkgs.llvmPackages_22.bintools;
  # lld   = pkgs.lld_22;
  lld = sergv.utils.filter-bin pkgs "llvmPackages_22.bintools" [
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
  patchelf        = pkgs.patchelf;
  pkg-config      = pkgs.pkg-config;
  universal-ctags = pkgs.universal-ctags;
} // lib.optionalAttrs sergv.isLinux {
  libtree = pkgs.libtree;
}
