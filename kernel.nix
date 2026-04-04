{ bore-scheduler-src, kernel-march-patches, linuk-tkg-src }:

{ self, lib, pkgs, ... }: {

  boot.kernelPackages =
    let kernel = pkgs.linuxKernel.kernels.linux_6_18.override (_: {
          argsOverride = {
            version       = "6.18.21";
            modDirVersion = "6.18.21";
            src           = pkgs.fetchurl {
              # url    = "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.18.21.tar.xz";
              url    = "mirror://kernel/linux/kernel/v6.18.x/linux-6.18.21.tar.xz";
              sha256 = "sha256-HDghT7E3uuhbgrglN7WYc1hiG5Fasqjk8J5gaXwZR08=";
            };
          };
        });

        patches = # builtins.abort kernel.version;
          import ./kernel-patches.nix {
            inherit lib bore-scheduler-src kernel-march-patches linuk-tkg-src;
            kernelVersion = lib.versions.majorMinor kernel.version;
          };

        # Inspired by
        # https://github.com/lovesegfault/nix-config/blob/db3262d344a10ed589539f834a15e9988f8dba0e/nix/overlays/linux-lto.nix
        # https://github.com/xddxdd/nix-cachyos-kernel/blob/master/helpers.nix
        # https://github.com/positron-solutions/derpconfig/blob/master/examples/kernel-clang.nix and https://github.com/positron-solutions/derpconfig/blob/master/examples/patches.nix
        # https://github.com/chaotic-cx/nyx/tree/main/pkgs/linux-cachyos

        # llvmPackages = "llvmPackages_14";
        llvmPackages = "llvmPackages";
        noBintools   = { bootBintools = null; bootBintoolsNoLibc = null; };
        hostLLVM     = pkgs.pkgsBuildHost.${llvmPackages}.override noBintools;
        buildLLVM    = pkgs.pkgsBuildBuild.${llvmPackages}.override noBintools;

        mkLLVMPlatform = platform: platform // {
          useLLVM = true;
          linux-kernel = platform.linux-kernel // {
            makeFlags = (platform.linux-kernel.makeFlags or []) ++ [
              "LLVM=1"
              "LLVM_IAS=1"
              "CC=${buildLLVM.clangUseLLVM}/bin/clang"
              "LD=${buildLLVM.lld}/bin/ld.lld"
              "HOSTLD=${hostLLVM.lld}/bin/ld.lld"
              "AR=${buildLLVM.llvm}/bin/llvm-ar"
              "HOSTAR=${hostLLVM.llvm}/bin/llvm-ar"
              "NM=${buildLLVM.llvm}/bin/llvm-nm"
              "STRIP=${buildLLVM.llvm}/bin/llvm-strip"
              "OBJCOPY=${buildLLVM.llvm}/bin/llvm-objcopy"
              "OBJDUMP=${buildLLVM.llvm}/bin/llvm-objdump"
              "READELF=${buildLLVM.llvm}/bin/llvm-readelf"
              "HOSTCC=${hostLLVM.clangUseLLVM}/bin/clang"
              "HOSTCXX=${hostLLVM.clangUseLLVM}/bin/clang++"
            ];
          };
        };

        stdenvClangUseLLVM = pkgs.overrideCC hostLLVM.stdenv hostLLVM.clangUseLLVM;
        stdenvPlatformLLVM = stdenvClangUseLLVM.override (old: {
          hostPlatform  = mkLLVMPlatform old.hostPlatform;
          buildPlatform = mkLLVMPlatform old.buildPlatform;
        });
        llvmStdenv = stdenvPlatformLLVM;

        llvm = kernel:
          kernel.override (old: {
            stdenv        = llvmStdenv;
            buildPackages = pkgs.buildPackages // { stdenv = llvmStdenv; };
          });

        finalPackages =
          (pkgs.linuxKernel.packagesFor ((llvm kernel).override (old: {
            argsOverride = old.argsOverride // {
              kernelPatches = old.kernelPatches ++ patches;
            };
          }))).extend (final: prev: {
            virtualbox = prev.virtualbox.overrideAttrs (final2: prev2: {
              # Export environment variable for kernel’s module compilation makefile.
              # It’s there where decision to pick clang vs gcc is taken, not in virtualbox’s makefile.
              "LLVM" = "1";
            });
          });

    in finalPackages;
}
