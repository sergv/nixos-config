{ pkgs }:

# stdenvNoCC is a packaging environment without compilers; we don't need them for fonts
pkgs.stdenvNoCC.mkDerivation {
  name = "iosevka-slab-lig";
  version = "32.4.0";

  srcs = [
    ./iosevka-slab-lig-normalbolditalic.ttf
    ./iosevka-slab-lig-normalboldupright.ttf
    ./iosevka-slab-lig-normalregularitalic.ttf
    ./iosevka-slab-lig-normalregularupright.ttf
  ];

  dontUnpack = true;

  installPhase =
    ''
      mkdir -p "$out/share/fonts/truetype/"
      ln -s $srcs $out/share/fonts/truetype/
    '';
}
