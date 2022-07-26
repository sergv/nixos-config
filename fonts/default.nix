{ pkgs }:
{ iosevka-slab-lig = import ./iosevka-slab-lig { inherit pkgs; };
  terminus         = import ./terminus { inherit pkgs; };
}
