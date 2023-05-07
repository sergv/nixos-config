{ pkgs }:

# stdenvNoCC is a packaging environment without compilers; we don't need them for fonts
pkgs.stdenvNoCC.mkDerivation {
  name = "iosevka-slab-lig";
  version = "1.2";

  srcs = [
    ./iosevka-slab-lig-bold.ttf
    ./iosevka-slab-lig-bolditalic.ttf
    ./iosevka-slab-lig-italic.ttf
    ./iosevka-slab-lig-regular.ttf
  ];

  dontUnpack = true;

  installPhase =
    ''
      mkdir -p "$out/share/fonts/truetype/"
      ln -s $srcs $out/share/fonts/truetype/
    '';
}
