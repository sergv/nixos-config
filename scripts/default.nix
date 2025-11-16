{ pkgs, wmctrl }:
let writePatchedScriptBin = name: buildInputs:
      let script = (pkgs.writeScriptBin name (builtins.readFile (./. + "/${name}"))).overrideAttrs (old: {
            buildCommand = "${old.buildCommand}\npatchShebangs \"$out\"";
          });
      in pkgs.symlinkJoin {
        inherit name;
        paths             = [ script ];
        postBuild         = "wrapProgram \"$out/bin/${name}\" --prefix PATH : \"$out/bin:${pkgs.lib.makeBinPath buildInputs}\"";
        nativeBuildInputs = [ pkgs.makeWrapper ];
      };
    reset-usb = writePatchedScriptBin "reset-usb" [];
in {
  inherit reset-usb;

  # Must be a clean script without mess produced wrapProgram or sg won’t work with errors like
  # > setgroups: Operation not permitted
  # > setgid: Operation not permitted
  no-internet             = pkgs.writeScriptBin "no-internet" ''
    #!${pkgs.bash}/bin/bash
    # Need to pass all argv as single string to sg
    exec sg no-internet "$*"
  '';

  pm-suspend              = writePatchedScriptBin "pm-suspend"              [];
  git-commit-on-date      = writePatchedScriptBin "git-commit-on-date"      [ pkgs.git ];
  reset-nixos-usb-network = writePatchedScriptBin "reset-nixos-usb-network" [ reset-usb ];
  tar7z                   = writePatchedScriptBin "tar7z"                   [ pkgs.gnutar pkgs.p7zip ];
  tar7zUltra              = writePatchedScriptBin "tar7zUltra"              [ pkgs.gnutar pkgs.p7zip ];
  targz                   = writePatchedScriptBin "targz"                   [ pkgs.gnutar pkgs.gzip ];
  targz-fast              = writePatchedScriptBin "targz-fast"              [ pkgs.gnutar pkgs.gzip ];
  tarbz2                  = writePatchedScriptBin "tarbz2"                  [ pkgs.gnutar pkgs.bzip2 ];
  tarlz                   = writePatchedScriptBin "tarlz"                   [ pkgs.gnutar pkgs.lzip ];
  tartar                  = writePatchedScriptBin "tartar"                  [ pkgs.gnutar ];
  tarxz                   = writePatchedScriptBin "tarxz"                   [ pkgs.gnutar pkgs.xz ];
  untar                   = writePatchedScriptBin "untar"                   [ pkgs.gnutar pkgs.p7zip pkgs.gzip pkgs.bzip2 pkgs.lzip pkgs.xz pkgs.zstd ];
  wm-sh                   = writePatchedScriptBin "wm.sh"                   [ pkgs.wmctrl pkgs.coreutils ];
}
