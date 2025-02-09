{ self, lib, ... }: {
  boot = {
    kernelPatches = lib.singleton {
      name = "Remove unused kernel parts";
      patch = null;
      extraStructuredConfig = {
        LRU_GEN                = lib.mkForce lib.kernel.yes;
        LRU_GEN_ENABLED        = lib.mkForce lib.kernel.yes;

        HZ_1000                = lib.mkForce lib.kernel.yes;
        UNWINDER_FRAME_POINTER = lib.mkForce lib.kernel.no;
        STACKPROTECTOR         = lib.mkForce lib.kernel.no;
        HIBERNATION            = lib.mkForce lib.kernel.no;
        X86_KERNEL_IBT         = lib.mkForce lib.kernel.no;
        PAGE_POISONING         = lib.mkForce lib.kernel.no;
        SLUB_DEBUG             = lib.mkForce lib.kernel.no;
        SCHED_STACK_END_CHECK  = lib.mkForce lib.kernel.no;
        DEBUG_VM               = lib.mkForce lib.kernel.no;
        DEBUG_VIRTUAL          = lib.mkForce lib.kernel.no;
        DEBUG_LIST             = lib.mkForce lib.kernel.no;
        DEBUG_PLIST            = lib.mkForce lib.kernel.no;
        DEBUG_SG               = lib.mkForce lib.kernel.no;
        DEBUG_NOTIFIERS        = lib.mkForce lib.kernel.no;
        DEBUG_MAPLE_TREE       = lib.mkForce lib.kernel.no;
        # DEBUG_CREDENTIALS      = lib.mkForce lib.kernel.no;
        SCHED_DEBUG            = lib.mkForce lib.kernel.no;
        SCHEDSTATS             = lib.mkForce lib.kernel.no;

        #FB_3DFX                 = lib.mkForce lib.kernel.no;
        FB_3DFX_ACCEL           = lib.mkForce lib.kernel.no;
        #FB_3DFX_I2C             = lib.mkForce lib.kernel.no;
        MLXSW_SPECTRUM          = lib.mkForce lib.kernel.no;
        MLX_PLATFORM            = lib.mkForce lib.kernel.no;

        # # # HOTPLUG_CPU = lib.mkForce lib.kernel.no;
        # # CPU_SUP_HYGON = lib.mkForce lib.kernel.no;
        # # CPU_SUP_CENTAUR = lib.mkForce lib.kernel.no;
        # # CPU_SUP_ZHAOXIN = lib.mkForce lib.kernel.no;
        # # # # ACPI_HOTPLUG_CPU = lib.mkForce lib.kernel.no;
        # # # ACPI_HOTPLUG_MEMORY = lib.mkForce lib.kernel.no;
        # # # ACPI_HOTPLUG_IOAPIC = lib.mkForce lib.kernel.no;
        # # # HOTPLUG_SMT = lib.mkForce lib.kernel.no;
        # # # ARCH_ENABLE_MEMORY_HOTPLUG = lib.mkForce lib.kernel.no;
        # # # ARCH_ENABLE_MEMORY_HOTREMOVE = lib.mkForce lib.kernel.no;
        # # MEMORY_HOTPLUG = lib.mkForce lib.kernel.no;
        # # HOTPLUG_PCI_PCIE = lib.mkForce lib.kernel.no;
        # # HOTPLUG_PCI = lib.mkForce lib.kernel.no;
        # # HOTPLUG_PCI_ACPI = lib.mkForce lib.kernel.no;
        # # INPUT_TABLET = lib.mkForce lib.kernel.no;
        # # INPUT_JOYSTICK = lib.mkForce lib.kernel.no;
        # # MOUSE_PS2 = lib.mkForce lib.kernel.no;
        # # # # INFINIBAND = lib.mkForce lib.kernel.no;
        # # UBIFS_FS = lib.mkForce lib.kernel.no;
        # # DEBUG_INFO = lib.mkForce lib.kernel.no;
        # HIBERNATION = lib.mkForce lib.kernel.no;
        # STACKPROTECTOR = lib.mkForce lib.kernel.no;
        # # STACKPROTECTOR_STRONG = lib.mkForce lib.kernel.no;
        # # # FIREWIRE = lib.mkForce lib.kernel.no;
        # # # FUSION = lib.mkForce lib.kernel.no;
        # # # MEMORY_HOTREMOVE = lib.mkForce lib.kernel.no;
        # # # SLUB_DEBUG = lib.mkForce lib.kernel.no;
        # # # SCHED_DEBUG = lib.mkForce lib.kernel.no;
        # # # SCHED_INFO = lib.mkForce lib.kernel.no;
        # # # LOCK_DEBUGGING_SUPPORT = lib.mkForce lib.kernel.no;
        # # # I2C = lib.mkForce lib.kernel.no;
      };

      # extraConfig = ''
      #   HOTPLUG_CPU n
      #   CPU_SUP_HYGON n
      #   CPU_SUP_CENTAUR n
      #   CPU_SUP_ZHAOXIN n
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
    };
  };
}
