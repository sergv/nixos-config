{ pkgs
}:
pkgs.isabelle.overrideAttrs (old:
  let isabelle-icon = ./icons/isabelle.png;
      getExt = x: pkgs.lib.lists.last (pkgs.lib.strings.splitString "." x);
      newDesktopItem = pkgs.makeDesktopItem {
        name        = "isabelle";
        exec        = "isabelle jedit";
        icon        = isabelle-icon;
        desktopName = "Isabelle";
        comment     = "A generic proof assistant";
        categories  = ["Math"];
      };
      newVersion = "2023";
      fixVersion = x: builtins.replaceStrings ["Isabelle2022"] ["Isabelle${newVersion}"] x;
  in
    {
      version = newVersion;
      src = pkgs.fetchurl {
        url    = "https://isabelle.in.tum.de/dist/Isabelle2023_linux.tar.gz";
        sha256 = "sha256-Go4ZCsDz5gJ7uWG5VLrNJOddMPX18G99FAadpX53Rqg="; # pkgs.lib.fakeSha256;
        # # url    = "https://isabelle.in.tum.de/website-Isabele2023/dist/Isabelle2023_linux.tar.gz";
        # sha256 = pkgs.lib.fakeSha256; # "1ih4gykkp1an43qdgc5xzyvf30fhs0dah3y0a5ksbmvmjsfnxyp7";
      };
      desktopItem = newDesktopItem;
      dirname = fixVersion old.dirname;
      patches = (old.patches or []) ++ [
        ./patches/VCSE-2023.patch
      ];
      sourceRoot = fixVersion old.sourceRoot;
      installPhase =
        fixVersion
          (builtins.replaceStrings
            [ # "${old.desktopItem}"
              "cp \"$out/Isabelle${old.version}/lib/icons/isabelle.xpm\" \"$out/share/icons/hicolor/isabelle/apps/\""
              "cp -r \"${old.desktopItem}/share/applications\" \"$out/share/applications\""
              # "${old.desktopItem}"
            ]
            [ # "${desktopItem}"
              # ""
              "ln -s \"${isabelle-icon}\" \"$out/share/icons/hicolor/isabelle/apps/isabelle.${getExt isabelle-icon}\""
              "ln -s \"${newDesktopItem}/share/applications\" \"$out/share/applications\""
              # "${newDesktopItem}"
            ]
            old.installPhase);
      postUnpack = fixVersion old.postUnpack;
      postPatch = fixVersion old.postPatch;
      # postInstall = builtins.replaceStrings [ "${old.desktopItem}" ] [ "${newDesktopItem}" ] old.postInstall;
      passthru.withComponents = f:
        (old.passthru.withComponents f).overrideAttrs (old2: {
          name = "isabelle-with-components-${newVersion}";
          postBuild = fixVersion old2.postBuild;
        });
    }
)
