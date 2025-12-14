{ pkgs
}:
let cuda   = pkgs.cudaPackages.cudatoolkit;
    cudart = pkgs.cudaPackages.cuda_cudart;

    # Need to patch produced executable in the end so that it will look up for libcuda.so
    # in /run/opengl-driver/lib directory.
    wrapped-nvcc = pkgs.writeScriptBin "nvcc"
      ''
        #!${pkgs.bash}/bin/bash
        set -eu

        target="a.out"
        target_is_next="0"

        for x in "''${@}"; do
          if [[ "$target_is_next" = 1 ]]; then
            target="$x"
            target_is_next="0"
          elif [[ "$x" = "-o" ]]; then
            target_is_next="1"
          elif [[ "$x" = "--output-file" ]]; then
            target_is_next="1"
          elif [[ "$x" = -o* ]]; then
            target="''${x#-o}"
          elif [[ "$x" = --output-file=* ]]; then
            target="''${x#--output-file=}"
          fi
        done

        "${cuda}/bin/nvcc" --compiler-bindir "${pkgs.gcc}/bin/gcc" --system-include "${cudart}/include" --library-path "${cudart}/lib" "''${@}"

        if [[ ! -z "$target" && -f "$target" ]]; then
          ${pkgs.patchelf}/bin/patchelf --add-rpath /run/opengl-driver/lib "$target"
        fi
    '';

    wrapped-cuda =
      pkgs.runCommand ("wrapped-cuda-" + cuda.version) {
        build-inputs = [ wrapped-nvcc cudart ];
      }
        ''
          mkdir -p "$out/bin"
          ln -s "${wrapped-nvcc}/bin/nvcc" "$out/bin/"
          for x in ${cuda}/bin/*; do
            if [[ "$x" != */nvcc && -f "$x" && -x "$x" ]]; then
              ln -s "$x" "$out/bin/"
            fi
          done
        '';

in {
  cuda = wrapped-cuda;
  # cuda-opencl = pkgs.cudaPackages.cuda_opencl;
}
