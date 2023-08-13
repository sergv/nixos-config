{ pkgs
}:
let
  isabelle-icon = ./icons/isabelle.png;
in

pkgs.isabelle.overrideAttrs (old:
  let newDesktopItem = pkgs.makeDesktopItem {
        name        = "isabelle";
        exec        = "isabelle jedit";
        icon        = isabelle-icon;
        desktopName = "Isabelle";
        comment     = "A generic proof assistant";
        categories  = ["Math"];
      };
  in
    {
      desktopItem = newDesktopItem;
      installPhase =
        builtins.replaceStrings
          [ # "${old.desktopItem}"
            "cp \"$out/Isabelle${old.version}/lib/icons/isabelle.xpm\" \"$out/share/icons/hicolor/isabelle/apps/\""
            "cp -r \"${old.desktopItem}/share/applications\" \"$out/share/applications\""
            # "${old.desktopItem}"
          ]
          [ # "${desktopItem}"
            # ""
            "ln -s \"${isabelle-icon}\" \"$out/share/icons/hicolor/isabelle/apps/isabelle.svg\""
            "ln -s \"${newDesktopItem}/share/applications\" \"$out/share/applications\""
            # "${newDesktopItem}"
          ]
          old.installPhase;
      # postInstall = builtins.replaceStrings [ "${old.desktopItem}" ] [ "${newDesktopItem}" ] old.postInstall;
    }
)
