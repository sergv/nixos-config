{
  pkgs,
  include-emacs-lsp-fixes,
}:
pkgs.isabelle.overrideAttrs (
  old:
  let
    isabelle-icon  = ./icons/isabelle.png;
    getExt         = x: pkgs.lib.lists.last (pkgs.lib.strings.splitString "." x);
    newDesktopItem = pkgs.makeDesktopItem {
      name        = "isabelle";
      exec        = "isabelle jedit";
      icon        = isabelle-icon;
      desktopName = "Isabelle";
      comment     = "A generic proof assistant";
      categories  = [ "Math" ];
    };
  in
  {
    src = pkgs.fetchurl {
      url    = "https://isabelle.in.tum.de/dist/Isabelle2025-2_linux.tar.gz";
      sha256 = "sha256-ogpQe8fBJw2L6WqfP77AY0U4d4nS3CxNPfYmDUe/szw="; # pkgs.lib.fakeSha256;
    };
    desktopItem  = newDesktopItem;
    patches      =
      (old.patches or [ ]) ++ (if include-emacs-lsp-fixes then [ ./patches/VCSE-2025-2.patch ] else [ ]);
    installPhase =
      builtins.replaceStrings
        [
          # "${old.desktopItem}"
          "cp \"$out/Isabelle${old.version}/lib/icons/isabelle.xpm\" \"$out/share/icons/hicolor/isabelle/apps/\""
          "cp -r \"${old.desktopItem}/share/applications\" \"$out/share/applications\""
          # "${old.desktopItem}"
        ]
        [
          # "${desktopItem}"
          # ""
          "ln -s \"${isabelle-icon}\" \"$out/share/icons/hicolor/isabelle/apps/isabelle.${getExt isabelle-icon}\""
          "ln -s \"${newDesktopItem}/share/applications\" \"$out/share/applications\""
          # "${newDesktopItem}"
        ]
        old.installPhase;
    # Need to remove some known dangling symlinks or ‘noBrokenSymlinks’ nix check will complain.
    postPatch = old.postPatch + ''
      find contrib/e-*/src/lib -xtype l -delete
    '';
  }
)
