{ config, pkgs, lib, ... }:
{
  options.sergv.system.nvidia = {
    enable = lib.mkEnableOption "Enable nvidia drivers";
  };

  config = lib.mkIf config.sergv.system.nvidia.enable
    {
      # OpenGL
      hardware.graphics = {
        enable      = true;
        # Enable acceleration in x32 wine apps.
        enable32Bit = true;
      };

      # Load NVIDIA driver for Xorg and Wayland
      services.xserver.videoDrivers = [ "nvidia" ];

      hardware.nvidia = {
        # # Modesetting is required for Wayland
        # modesetting.enable = true;

        modesetting.enable = false;

        # Enable power management (do not disable this unless you have a reason to).
        # Likely to cause problems on laptops and with screen tearing if disabled.
        powerManagement.enable = true;
        # powerManagement.finegrained = todo;

        # Use the open source version of the kernel module ("nouveau")
        # Note that this offers much lower performance and does not
        # support all the latest Nvidia GPU features.
        # You most likely don't want this.
        # Only available on driver 515.43.04+
        open = false;

        prime.offload.enable = false;

        # Enable the Nvidia settings menu,
        # accessible via `nvidia-settings`.
        nvidiaSettings = true;

        # Optionally, you may need to select the appropriate driver version for your specific GPU.
        package = config.boot.kernelPackages.nvidiaPackages.stable;
        # package = config.boot.kernelPackages.nvidiaPackages.production;
      };

      # Environment variables for NVIDIA + Wayland
      environment.sessionVariables = {
        # Fix cursor issues on Wayland
        WLR_NO_HARDWARE_CURSORS   = "1";

        # Hardware acceleration
        LIBVA_DRIVER_NAME         = "nvidia";
        GBM_BACKEND               = "nvidia-drm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";

        # Enable Wayland for Electron apps
        NIXOS_OZONE_WL            = "1";
      };

      boot.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
    };
}

