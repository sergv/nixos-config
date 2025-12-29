{ bore-scheduler-src, kernel-march-patches, linuk-tkg-src, lib, kernelVersion }:
  let yes           = lib.mkForce lib.kernel.yes;
      no            = lib.mkForce lib.kernel.no;
      unset         = lib.mkForce lib.kernel.unset;
      freeform      = x: lib.mkForce (lib.kernel.freeform x);
      patchesDir    =
        "${bore-scheduler-src}/patches/stable/linux-${kernelVersion}-bore";

      mkPatch       = name: patch: structuredExtraConfig: {
        inherit name patch structuredExtraConfig;
      };

      borePatches   =
        lib.mapAttrsToList
          (name: _fileType:
            mkPatch "bore-${name}" "${patchesDir}/${name}" {})
          (builtins.readDir patchesDir);

  in borePatches ++ [

    (mkPatch
      "add-more-march-variants"
      (kernel-march-patches + "/more-ISA-levels-and-uarches-for-kernel-6.16+.patch")
      {
        # X86_64_VERSION = freeform "ZEN4";
        MZEN4            = yes;
        # X86_NATIVE_CPU = yes;
      })

    (mkPatch
      "custom-kernel-timer-frequency"
      (linuk-tkg-src + "/linux-tkg-patches/${kernelVersion}/0003-glitched-cfs.patch")
      {
        # Middle ground between 250 and 1000, 250 favours computation, 1000 - interrupts.
        # https://www.phoronix.com/news/Linux-250Hz-1000Hz-Kernel-2025
        HZ_500  = yes;

        # HZ_750    = yes;

        # # 1000hz should work better with 120hz screen refresh rate...
        # HZ_1000 = yes;

      })

    {
      name = "Optimise performance";
      patch = null;
      structuredExtraConfig = {
        NR_CPUS                      = freeform "32";

        LRU_GEN                      = yes;
        LRU_GEN_ENABLED              = yes;

        TRANSPARENT_HUGEPAGE_MADVISE = no;
        TRANSPARENT_HUGEPAGE_ALWAYS  = yes;

        SCHED_BORE                   = yes;

        # Omit scheduling-clock ticks on idle CPUs (CONFIG_NO_HZ_IDLE=y)
        # This should be simpler than CONFIG_NO_HZ_FULL=y and equivalent to it
        # when no nohz_full= parameters are configured.
        #
        # Distros usually go for CONFIG_NO_HZ_FULL=y but don’t configure nohz_full=
        # so it’s pretty equivalent in the end.
        #
        # idle in CachyOS - https://github.com/xddxdd/nix-cachyos-kernel/blob/master/kernel-cachyos/cachySettings.nix#L55
        HZ_PERIODIC                  = no; # yes = never omit scheduling-clock ticks
        NO_HZ_FULL                   = no;
        NO_HZ_IDLE                   = yes;
        NO_HZ                        = yes;
        NO_HZ_COMMON                 = yes;

        # Remove some hardening
        SLAB_FREELIST_HARDENED   = unset;
        INIT_STACK_ALL_ZERO      = unset;
        INIT_ON_ALLOC_DEFAULT_ON = unset;
        DEBUG_MISC               = unset;
        SYMBOLIC_ERRNAME         = unset;
        DYNAMIC_DEBUG            = unset;


        PRINTK                      = yes;
        PRINTK_INDEX                = unset;
        PRINTK_CALLER               = no;
        RD_LZO                      = no;
        RD_LZ4                      = no;
        RD_BZIP2                    = no;
        INITRAMFS_COMPRESSION_LZO   = unset;
        INITRAMFS_COMPRESSION_LZ4   = unset;
        INITRAMFS_COMPRESSION_BZIP2 = unset;
        # DEBUG_KERNEL = no;

        CONFIG_SECURITY_DMESG_RESTRICT = unset;

        # # Omit scheduling-clock ticks on CPUs that are either idle
        # # or that have only one runnable task (CONFIG_NO_HZ_FULL=y).
        # # Need to manually configure nohz_full= kernel boot parameter listing all CPUs
        # # that would run one task only uninterrupted.
        #
        # # full in CachyOS https://github.com/xddxdd/nix-cachyos-kernel/blob/master/kernel-cachyos/cachySettings.nix#L62
        # HZ_PERIODIC            = no;
        # NO_HZ_IDLE             = no;
        # CONTEXT_TRACKING_FORCE = no;
        # NO_HZ_FULL_NODEF       = yes;
        # NO_HZ_FULL             = yes;
        # NO_HZ                  = yes;
        # NO_HZ_COMMON           = yes;
        # CONTEXT_TRACKING       = yes;
        #
        # # # Enable nohz_full for all CPUs - settings not available
        # # CONFIG_NO_HZ_FULL_ALL  = yes;
        #
        # # Offload RCUs to dedicated cpus to reduce overheads introduced by NO_HZ_FULL.
        # RCU_NOCB_DEFAULT_ALL   = yes;

        # Compress modules to save space.
        MODULE_COMPRESS_ALL  = yes;
        MODULE_COMPRESS_XS   = unset;
        MODULE_COMPRESS_ZSTD = unset;

        # Preempt lazy - recovers some performance gains of
        # voluntary preemption (typically found on servers) that
        # are lost in full preemption (typically found on
        # desktop).
        PREEMPT_DYNAMIC              = yes;
        PREEMPT                      = no;
        PREEMPT_VOLUNTARY            = no;
        PREEMPT_LAZY                 = yes;
        PREEMPT_NONE                 = no;

        # From Zen
        # Preemptible tree-based hierarchical RCU
        TREE_RCU                 = yes;
        PREEMPT_RCU              = yes;
        RCU_EXPERT               = yes;
        TREE_SRCU                = yes;
        TASKS_RCU_GENERIC        = yes;
        TASKS_RCU                = yes;
        TASKS_RUDE_RCU           = yes;
        TASKS_TRACE_RCU          = yes;
        RCU_STALL_COMMON         = yes;
        RCU_NEED_SEGCBLIST       = yes;
        RCU_FANOUT               = freeform "64";
        RCU_FANOUT_LEAF          = freeform "16";
        RCU_BOOST                = yes;
        RCU_BOOST_DELAY          = freeform "500";
        RCU_NOCB_CPU             = yes;
        RCU_LAZY                 = yes;
        RCU_DOUBLE_CHECK_CB_TIME = yes;

        # Futex WAIT_MULTIPLE implementation for Wine / Proton Fsync.
        FUTEX = yes;
        FUTEX_PI = yes;

        # NT synchronization primitive emulation
        NTSYNC = yes;

        # Clang options require a lot of extra config
        CC_IS_CLANG            = yes;
        LTO_NONE               = no;
        LTO                    = yes;
        LTO_CLANG              = yes;
        LTO_CLANG_THIN         = yes;
        # full LTO is much more expsneive
        # LTO_CLANG_FULL = yes;

      };
    }

    # Make kernel smaller
    {
      name = "Remove unused kernel parts";
      patch = null;
      # ignoreConfigErrors = true;
      structuredExtraConfig = {

        # We don’t have multiple processors.
        NUMA                           = no;
        AMD_NUMA                       = unset;
        X86_64_ACPI_NUMA               = unset;
        NODES_SPAN_OTHER_NODES         = unset;
        NUMA_EMU                       = unset;
        USE_PERCPU_NUMA_NODE_ID        = unset;
        ACPI_NUMA                      = unset;
        # ARCH_SUPPORTS_NUMA_BALANCING   = no;
        NODES_SHIFT                    = unset;
        NEED_MULTIPLE_NODES            = unset;
        NUMA_BALANCING                 = unset;
        NUMA_BALANCING_DEFAULT_ENABLED = unset;
        # NODES_SHIFT                    = unset;

        NET_SCH_BPF = unset;

        # Reduce some debugging capabilities
        STACK_TRACER                   = no;

        UNWINDER_FRAME_POINTER = no;
        HIBERNATION            = no;
        X86_KERNEL_IBT         = no;
        PAGE_POISONING         = no;
        SLUB_DEBUG             = no;
        SCHED_STACK_END_CHECK  = no;
        DEBUG_VM               = no;
        DEBUG_WX               = no;
        STACKPROTECTOR         = no;
        STACKPROTECTOR_STRONG  = unset;
        DEBUG_VIRTUAL          = no;
        DEBUG_LIST             = no;
        DEBUG_PLIST            = no;
        DEBUG_SG               = no;
        DEBUG_NOTIFIERS        = no;
        DEBUG_MAPLE_TREE       = no;
        # DEBUG_CREDENTIALS      = no;
        SCHED_DEBUG            = unset;
        SCHEDSTATS             = no;

        #FB_3DFX                 = no;
        # FB_3DFX_ACCEL          = no;
        #FB_3DFX_I2C             = no;
        MLXSW_SPECTRUM         = no;
        MLX_PLATFORM           = unset;

        # Sometimes doesn’t build and is not needed
        NET_VENDOR_CAVIUM      = no;

        # Debug info that consumes a lot of both RAM and on-disk space during build.
        # Disabling this causes SCHED_CLASS_EXT to become unused so we need to unset it.
        DEBUG_INFO_BTF         = no;
        SCHED_CLASS_EXT        = unset;

        CPU_MITIGATIONS           = no;
        MITIGATION_SLS            = unset;
        SECURITY_SELINUX          = no;
        SECURITY_APPARMOR         = no;
        DEFAULT_SECURITY_APPARMOR = unset;

        DEBUG_INFO                             = unset;
        SCHED_INFO                             = unset;
        DEBUG_KERNEL                           = unset;
        NETCONSOLE                             = no;
        # NETCONSOLE_DYNAMIC                     = no;
        MEM_ALLOC_PROFILING                    = no;
        # MEM_ALLOC_PROFILING_ENABLED_BY_DEFAULT = no;

        # Smaller size
        STRIP_ASM_SYMS = yes;

        # We’re not VM
        KVM                      = no;
        KVM_GUEST                = unset;
        MOUSE_PS2_VMMOUSE        = unset;
        # XEN                    = unset;
        HYPERV                   = unset;
        PARAVIRT_TIME_ACCOUNTING = unset;
        HYPERVISOR_GUEST         = no;

        # Fallout
        DRM_HYPERV                             = unset;
        DRM_I915_GVT                           = unset;
        DRM_I915_GVT_KVMGT                     = unset;
        FB_HYPERV                              = unset;
        HVC_XEN                                = unset;
        HVC_XEN_FRONTEND                       = unset;
        INTEL_TDX_GUEST                        = unset;
        KEXEC_JUMP                             = unset;
        KVM_AMD_SEV                            = unset;
        KVM_ASYNC_PF                           = unset;
        KVM_GENERIC_DIRTYLOG_READ_PROTECT      = unset;
        KVM_MMIO                               = unset;
        KVM_VFIO                               = unset;
        MEM_ALLOC_PROFILING_ENABLED_BY_DEFAULT = unset;
        MODULE_ALLOW_BTF_MISMATCH              = unset;
        NETCONSOLE_DYNAMIC                     = unset;
        PARAVIRT                               = unset;
        PARAVIRT_SPINLOCKS                     = unset;
        PCI_XEN                                = unset;
        POWER_RESET_GPIO                       = unset;
        POWER_RESET_GPIO_RESTART               = unset;
        SWIOTLB_XEN                            = unset;
        TDX_GUEST_DRIVER                       = unset;
        X86_SGX_KVM                            = unset;
        XEN                                    = unset;
        XEN_BACKEND                            = unset;
        XEN_BALLOON                            = unset;
        XEN_BALLOON_MEMORY_HOTPLUG             = unset;
        XEN_DOM0                               = unset;
        XEN_EFI                                = unset;
        XEN_HAVE_PVMMU                         = unset;
        XEN_MCE_LOG                            = unset;
        XEN_PVH                                = unset;
        XEN_PVHVM                              = unset;
        XEN_SAVE_RESTORE                       = unset;
        XEN_SYS_HYPERVISOR                     = unset;
        ZONE_DEVICE                            = unset;
        PCI_P2PDMA                             = unset;
        HSA_AMD_P2P                            = unset;
        DRM_NOUVEAU_SVM                        = unset;
        DEVICE_PRIVATE                         = unset;
        MHP_DEFAULT_ONLINE_TYPE_ONLINE_AUTO    = unset;

        # no old devices
        UDF_FS               = no;
        JFS_FS               = no;
        EXT2_FS              = no;
        EXT3_FS              = no;
        GFS2_FS              = no;
        OCFS2_FS             = no;
        # BTRFS_FS             = no;
        NILFS2_FS            = no;
        # BCACHEFS_FS          = no;
        ZONEFS_FS            = no;
        MISC_FILESYSTEMS     = unset;
        NETWORK_FILESYSTEMS  = no;

        # # some 3rd party programs may be 32-bit compiled.  But these days, few.
        # IA32_EMULATION       = no;

        # SATA_AHCI            = module;

        # No old disks
        # SCSI                 = no;
        # # SCSI_COMMON        = no; # really wants this to be a module 🤷
        # ATA                  = no;

        # # No old USB
        # USB_OHCI_HCD         = no;
        # USB_UHCI_HCD         = no;

        # Parallel port
        PARPORT              = no;

        # No old graphics
        FB_VESA              = unset;

        # no CD ROM (will also limit reads of dual-use flash drive images?)
        # those images mainly need to be read by your EFI anyway
        ISO9660_FS           = no;

        X86_POWERNOW_K8      = no;
        X86_ACPI_CPUFREQ_CPB = no;
        MTTR                 = unset;

        ATALK                = no;

        ISA                  = unset;
        ISAPNP               = unset;
        PNP                  = unset;
        PCI_GO_ANY           = unset;
        PCI_QUIRKS           = no;
        TR                   = unset;
        ARCNET               = no;
        FDDI                 = no;
        # DLCI               = no;
        # FRAMERELAY         = no;
        MTD                  = no;
        HID_GYRATION         = no;
        HID_SUNPLUS          = no;
        VIDEO_V4L1           = unset;
        RADIO_ADAPTERS       = unset;
        # DVB                = unset;
        I2O                  = unset;
        IRDA                 = unset;
        BT_HIDP              = no;
        BT_RFCOMM            = no;
        BT_BNEP              = no;
        NET_DSA_LEGACY       = unset;
        # PPP                = no; # already no
        SLIP                 = unset;
        PLIP                 = unset;
        NET_SB1000           = unset;
        IEEE1394             = unset;
        FB                   = no;
        OLPC                 = unset;
        # W1                 = no;
        X86_16BIT            = unset;

        RAPIDIO              = no;

        # # Realtek?
        # RTLWIFI              = unset;
        # RTLWIFI_PCI          = unset;

        # old USB cameras
        USB_GSPCA            = no;

        # # I mean, sure, if I'm consoling into a server rack
        # USB_SERIAL           = no;
        # USB_SERIAL_CONSOLE   = unset;
        # USB_SERIAL_GENERIC   = unset;

        # disable rare devices

        SURFACE_PLATFORMS     = no;
        FIREWIRE              = no;
        MACINTOSH_DRIVERS     = no;
        INFINIBAND            = no;
        ATM                   = no;
        IIO                   = no;
        SPEAKUP               = no;
        # TINYDRM               = no; # already unset
        RC_LOOPBACK           = no;
        RC_ATI_REMOTE         = no;
        RC_XBOX_DVD           = no;

        # said to be for testing only
        RCU_REF_SCALE_TEST    = no;
        SCF_TORTURE_TEST      = no;
        TEST_LOCKUP           = no;
        TEST_POWER            = no;
        THERMAL_CORE_TESTING  = no;

        X86_EXTENDED_PLATFORM = no;

        CPU_SUP_HYGON         = unset;
        CPU_SUP_CENTAUR       = unset;
        CPU_SUP_ZHAOXIN       = unset;

        # Fallout #2
        "9P_FSCACHE"                          = unset;
        "9P_FS_POSIX_ACL"                     = unset;
        AIC79XX_DEBUG_ENABLE                  = unset;
        AIC7XXX_DEBUG_ENABLE                  = unset;
        AIC94XX_DEBUG                         = unset;
        BT_RFCOMM_TTY                         = unset;
        CEPH_FSCACHE                          = unset;
        CEPH_FS_POSIX_ACL                     = unset;
        CIFS_DFS_UPCALL                       = unset;
        CIFS_FSCACHE                          = unset;
        CIFS_POSIX                            = unset;
        CIFS_UPCALL                           = unset;
        CIFS_XATTR                            = unset;
        EXT2_FS_POSIX_ACL                     = unset;
        EXT2_FS_SECURITY                      = unset;
        EXT2_FS_XATTR                         = unset;
        EXT3_FS_POSIX_ACL                     = unset;
        EXT3_FS_SECURITY                      = unset;
        FB_3DFX_ACCEL                         = unset;
        FB_ATY_CT                             = unset;
        FB_ATY_GX                             = unset;
        FB_EFI                                = unset;
        FB_NVIDIA_I2C                         = unset;
        FB_RIVA_I2C                           = unset;
        FB_SAVAGE_ACCEL                       = unset;
        FB_SAVAGE_I2C                         = unset;
        FB_SIS_300                            = unset;
        FB_SIS_315                            = unset;
        FRAMEBUFFER_CONSOLE_DEFERRED_TAKEOVER = unset;
        FSCACHE_STATS                         = unset;
        INFINIBAND_IPOIB                      = unset;
        INFINIBAND_IPOIB_CM                   = unset;
        JFS_POSIX_ACL                         = unset;
        JFS_SECURITY                          = unset;
        MEGARAID_NEWGEN                       = unset;
        MTD_COMPLEX_MAPPINGS                  = unset;
        MTD_TESTS                             = unset;
        NET_FC                                = unset;
        NFSD_V3_ACL                           = unset;
        NFSD_V4                               = unset;
        NFSD_V4_SECURITY_LABEL                = unset;
        NFS_FS                                = unset;
        NFS_FSCACHE                           = unset;
        NFS_LOCALIO                           = unset;
        NFS_SWAP                              = unset;
        NFS_V3_ACL                            = unset;
        NFS_V4_1                              = unset;
        NFS_V4_2                              = unset;
        NFS_V4_SECURITY_LABEL                 = unset;
        NVIDIA_SHIELD_FF                      = unset;
        OCFS2_DEBUG_MASKLOG                   = unset;
        SATA_MOBILE_LPM_POLICY                = unset;
        SCSI_LOGGING                          = unset;
        SCSI_LOWLEVEL                         = unset;
        SCSI_LOWLEVEL_PCMCIA                  = unset;
        SCSI_SAS_ATA                          = unset;
        SUNRPC_DEBUG                          = unset;
        TINYDRM                               = unset;
        UBIFS_FS_ADVANCED_COMPR               = unset;
        VGA_SWITCHEROO                        = unset;

        #
        # INPUT_JOYSTICK        = yes;
        #
        # # Disable unused options
        # "9P_FSCACHE"                           = unset;
        # "9P_FS_POSIX_ACL"                      = unset;
        # AIC79XX_DEBUG_ENABLE                   = unset;
        # AIC7XXX_DEBUG_ENABLE                   = unset;
        # AIC94XX_DEBUG                          = unset;
        # BT_RFCOMM_TTY                          = unset;
        # CEPH_FSCACHE                           = unset;
        # CEPH_FS_POSIX_ACL                      = unset;
        # CIFS_DFS_UPCALL                        = unset;
        # CIFS_FSCACHE                           = unset;
        # CIFS_POSIX                             = unset;
        # CIFS_UPCALL                            = unset;
        # CIFS_XATTR                             = unset;
        # DRM_I915_GVT                           = unset;
        # DRM_I915_GVT_KVMGT                     = unset;
        # EXT2_FS_POSIX_ACL                      = unset;
        # EXT2_FS_SECURITY                       = unset;
        # EXT2_FS_XATTR                          = unset;
        # EXT3_FS_POSIX_ACL                      = unset;
        # EXT3_FS_SECURITY                       = unset;
        # FB_3DFX_ACCEL                          = unset;
        # FB_ATY_CT                              = unset;
        # FB_ATY_GX                              = unset;
        # FB_EFI                                 = unset;
        # FB_HYPERV                              = unset;
        # FB_NVIDIA_I2C                          = unset;
        # FB_RIVA_I2C                            = unset;
        # FB_SAVAGE_ACCEL                        = unset;
        # FB_SAVAGE_I2C                          = unset;
        # FB_SIS_300                             = unset;
        # FB_SIS_315                             = unset;
        # FRAMEBUFFER_CONSOLE_DEFERRED_TAKEOVER  = unset;
        # FSCACHE_STATS                          = unset;
        # HVC_XEN                                = unset;
        # HVC_XEN_FRONTEND                       = unset;
        # INFINIBAND_IPOIB                       = unset;
        # INFINIBAND_IPOIB_CM                    = unset;
        # INTEL_TDX_GUEST                        = unset;
        # JFS_POSIX_ACL                          = unset;
        # JFS_SECURITY                           = unset;
        # KEXEC_JUMP                             = unset;
        # KVM_AMD_SEV                            = unset;
        # KVM_ASYNC_PF                           = unset;
        # KVM_GENERIC_DIRTYLOG_READ_PROTECT      = unset;
        # KVM_MMIO                               = unset;
        # KVM_VFIO                               = unset;
        # MEGARAID_NEWGEN                        = unset;
        # MEM_ALLOC_PROFILING_ENABLED_BY_DEFAULT = unset;
        # MODULE_ALLOW_BTF_MISMATCH              = unset;
        # MTD_COMPLEX_MAPPINGS                   = unset;
        # MTD_TESTS                              = unset;
        # NETCONSOLE_DYNAMIC                     = unset;
        # NET_FC                                 = unset;
        # NFSD_V3_ACL                            = unset;
        # NFSD_V4                                = unset;
        # NFSD_V4_SECURITY_LABEL                 = unset;
        # NFS_FS                                 = unset;
        # NFS_FSCACHE                            = unset;
        # NFS_LOCALIO                            = unset;
        # NFS_SWAP                               = unset;
        # NFS_V3_ACL                             = unset;
        # NFS_V4_1                               = unset;
        # NFS_V4_2                               = unset;
        # NFS_V4_SECURITY_LABEL                  = unset;
        # NVIDIA_SHIELD_FF                       = unset;
        # OCFS2_DEBUG_MASKLOG                    = unset;
        # PARAVIRT                               = unset;
        # PARAVIRT_SPINLOCKS                     = unset;
        # PCI_XEN                                = unset;
        # POWER_RESET_GPIO                       = unset;
        # POWER_RESET_GPIO_RESTART               = unset;
        # SATA_MOBILE_LPM_POLICY                 = unset;
        # SCSI_LOGGING                           = unset;
        # SCSI_LOWLEVEL                          = unset;
        # SCSI_LOWLEVEL_PCMCIA                   = unset;
        # SCSI_SAS_ATA                           = unset;
        # SUNRPC_DEBUG                           = unset;
        # SWIOTLB_XEN                            = unset;
        # UBIFS_FS_ADVANCED_COMPR                = unset;
        # VGA_SWITCHEROO                         = unset;
        # X86_SGX_KVM                            = unset;

        # ZPOOL                                  = unset;
        # ZSWAP_COMPRESSOR_DEFAULT_ZSTD          = unset;
        # ZSWAP_DEFAULT_ON                       = unset;

        HOTPLUG_CPU                  = unset;
        ACPI_HOTPLUG_IOAPIC          = unset;
        ARCH_ENABLE_MEMORY_HOTPLUG   = unset;
        HOTPLUG_SMT                  = unset;
        ACPI_HOTPLUG_CPU             = unset;
        MEMORY_HOTPLUG               = no;
        HOTPLUG_PCI                  = no;
        ACPI_HOTPLUG_MEMORY          = unset;
        ARCH_ENABLE_MEMORY_HOTREMOVE = unset;
        MEMORY_HOTREMOVE             = unset;
        HOTPLUG_PCI_PCIE             = unset;
        HOTPLUG_PCI_ACPI             = unset;

        # # INPUT_TABLET = no;
        # # INPUT_JOYSTICK = no;
        # # MOUSE_PS2 = no;
        # # # # INFINIBAND = no;
        # # UBIFS_FS = no;
        # # DEBUG_INFO = no;
        # HIBERNATION = no;
        # STACKPROTECTOR = no;
        # # STACKPROTECTOR_STRONG = no;
        # # # FIREWIRE = no;
        # # # FUSION = no;
        # # # MEMORY_HOTREMOVE = no;
        # # # SLUB_DEBUG = no;
        # # # SCHED_DEBUG = no;
        # # # SCHED_INFO = no;
        # # # LOCK_DEBUGGING_SUPPORT = no;
        # # # I2C = no;
      };

      # extraConfig = ''
      #   HOTPLUG_CPU n
      #   ACPI_HOTPLUG_CPU n
      #   ACPI_HOTPLUG_MEMORY n
      #   ACPI_HOTPLUG_IOAPIC n
      #   HOTPLUG_SMT n
      #   ARCH_ENABLE_MEMORY_HOTPLUG n
      #   ARCH_ENABLE_MEMORY_HOTREMOVE n
      #   MEMORY_HOTPLUG n
      #   HOTPLUG_PCI_PCIE n
      #   HOTPLUG_PCI n
      #   HOTPLUG_PCI_ACPI n
      #   INPUT_TABLET n
      #   INPUT_JOYSTICK n
      #   MOUSE_PS2 n
      #   INFINIBAND n
      #   UBIFS_FS n
      #   DEBUG_INFO n
      #   HIBERNATION n
      #   STACKPROTECTOR n
      #   STACKPROTECTOR_STRONG n
      #   FIREWIRE n
      #   FUSION n
      #   MEMORY_HOTREMOVE n
      # '';
      #   # SLUB_DEBUG n
      #   # SCHED_DEBUG n
      #   # SCHED_INFO n
      #   # LOCK_DEBUGGING_SUPPORT n
      #   # I2C n
    }
  ]
