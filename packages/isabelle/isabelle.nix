{
  pkgs,
  include-emacs-lsp-fixes,
}:
(pkgs.isabelle.override (old: {
  electron = "";
})).overrideAttrs
  (
    old:
    let
      isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

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
        url    =
          if isDarwin
          then "https://isabelle.in.tum.de/website-Isabelle2025-2/dist/Isabelle2025-2_macos.tar.gz"
          else "https://isabelle.in.tum.de/website-Isabelle2025-2/dist/Isabelle2025-2_linux.tar.gz";
        sha256 =
          if isDarwin
          then "sha256-jxh0luKV8WmVLpRHRa+eSuAMnBzS7UytvPfYmOREkT4="
          else "sha256-ogpQe8fBJw2L6WqfP77AY0U4d4nS3CxNPfYmDUe/szw="; # pkgs.lib.fakeSha256;
      };
      desktopItem = newDesktopItem;
      patches     =
        (old.patches or [ ])
        ++ (if include-emacs-lsp-fixes then [ ./patches/VCSE-2025-2.patch ] else [ ])
        ++ [ patches/0001-recover-json_entries-from-b2857541a531-required-for-.patch ];

      postUnpack = old.postUnpack + ''
        rm -r $sourceRoot/contrib/vscodium*/
      '';

      # z3-based tests fail on MacOS
      # *** Solver z3: Solver terminated abnormally with error code 126
      # *** At command "by" (line 26 of "~~/src/HOL/SMT_Examples/SMT_Tests.thy")
      doCheck = !isDarwin;

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

      postPatch =
        let
          old-without-vscodium = pkgs.lib.strings.concatLines (
            builtins.filter (
              x: !(pkgs.lib.strings.hasInfix "/electron" x || pkgs.lib.strings.hasInfix "contrib/vscodium" x)
            ) (pkgs.lib.strings.splitString "\n" old.postPatch)
          );
          # Need to remove some known dangling symlinks or ‘noBrokenSymlinks’ nix check will complain.
          new-remove-dangling-symlinks = ''
            find contrib/e-*/src/lib -xtype l -delete
          '';
        in
        old-without-vscodium + new-remove-dangling-symlinks;
    }
  )
