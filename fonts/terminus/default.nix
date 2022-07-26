{ pkgs }:

# stdenvNoCC is a packaging environment without compilers; we don't need them for fonts
pkgs.stdenvNoCC.mkDerivation {
  name = "terminus";
  version = "4.38";

  srcs = [
    ./TerminusTTF-4.38.2.ttf
    ./TerminusTTF-Bold-4.38.2.ttf
    ./TerminusTTF-Italic-4.38.2.ttf
  ];

  dontUnpack = true;

  installPhase =
    ''
      mkdir -p "$out/share/fonts/truetype/"
      ln -s $srcs $out/share/fonts/truetype/
    '';
}
