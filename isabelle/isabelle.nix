{ pkgs
}:
let naproche = pkgs.naproche.overrideAttrs (old: {
      src = pkgs.fetchFromGitHub {
        owner  = "naproche";
        repo   = "naproche";
        # rev    = "d7f514b575db99f84ffb70cfbba22bd9078bba96";
        # sha256 = "sha256-BAKD2zj5+E2y2uHiGJ/mshD6PSrAAp2ucR/r+ZSLBMk="; #pkgs.lib.fakeSha256;
        rev    = "ccb35e6eeb31c82bdd8857d5f84deda296ed53ec";
        hash   = "sha256-pIRKjbSFP1q8ldMZXm0WSP0FJqy/lQslNQcoed/y9W0=";
      };
      doCheck = false;
    });
in
(pkgs.isabelle.override (old: old // {
  inherit naproche;
  java    = pkgs.openjdk21;
  polyml = old.polyml.overrideAttrs (old2: {
    version = "2024";
    src = pkgs.fetchFromGitHub {
      owner   = "polyml";
      repo    = "polyml";
      rev     = "v5.9.1";
      hash    = "sha256-72wm8dt+Id59A5058mVE5P9TkXW5/LZRthZoxUustVA=";
    };
  });
})).overrideAttrs (old:
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
      newVersion = "2024";
      fixVersion = x: builtins.replaceStrings ["2023"] ["${newVersion}"] x;
  in
    {
      version = newVersion;
      src = pkgs.fetchurl {
        url    = "https://isabelle.in.tum.de/dist/Isabelle2024_linux.tar.gz";
        sha256 = "sha256-YDqq+KvqNll687BlHSwWKobAoN1EIHZvR+VyQDljkmc="; # pkgs.lib.fakeSha256;
        # # url    = "https://isabelle.in.tum.de/website-Isabele2023/dist/Isabelle2023_linux.tar.gz";
        # sha256 = pkgs.lib.fakeSha256; # "1ih4gykkp1an43qdgc5xzyvf30fhs0dah3y0a5ksbmvmjsfnxyp7";
      };
      desktopItem = newDesktopItem;
      dirname = fixVersion old.dirname;
      patches = (old.patches or []) ++ [
        ./patches/VCSE-2024.patch
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
      postPatch =
        builtins.replaceStrings
          [ "{z3,epclextract,nunchaku,SPASS,zipperposition}"
            "contrib/bash_process-*/platform_$arch/bash_process"
          ]
          [ "{z3,nunchaku,spass,zipperposition}"
            "contrib/bash_process-*/$arch/bash_process"
          ]
        (fixVersion old.postPatch);
      # postInstall = builtins.replaceStrings [ "${old.desktopItem}" ] [ "${newDesktopItem}" ] old.postInstall;
      passthru.withComponents = f:
        (old.passthru.withComponents f).overrideAttrs (old2: {
          name = "isabelle-with-components-${newVersion}";
          postBuild = fixVersion old2.postBuild;
        });
    }
)
