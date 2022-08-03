{ pkgs, wmctrl }:
let writePatchedScriptBin = name: buildInputs:
      let script = (pkgs.writeScriptBin name (builtins.readFile (./. + "/${name}"))).overrideAttrs (old: {
            buildCommand = "${old.buildCommand}\npatchShebangs \"$out\"";
          });
      in pkgs.symlinkJoin {
        inherit name;
        paths       = [ script ] ++ buildInputs;
        buildInputs = [ pkgs.makeWrapper ];
        postBuild   = "wrapProgram \"$out/bin/${name}\" --prefix PATH : \"$out/bin\"";
      };
    reset-usb = writePatchedScriptBin "reset-usb" [];
in {
  inherit reset-usb;
  reset-nixos-usb-network = writePatchedScriptBin "reset-nixos-usb-network" [ reset-usb ];
  tar7z                   = writePatchedScriptBin "tar7z"                   [ pkgs.gnutar pkgs.p7zip ];
  tar7zUltra              = writePatchedScriptBin "tar7zUltra"              [ pkgs.gnutar pkgs.p7zip ];
  targz                   = writePatchedScriptBin "targz"                   [ pkgs.gnutar pkgs.gzip ];
  targz-fast              = writePatchedScriptBin "targz-fast"              [ pkgs.gnutar pkgs.gzip ];
  tarbz2                  = writePatchedScriptBin "tarbz2"                  [ pkgs.gnutar pkgs.bzip2 ];
  tarlz                   = writePatchedScriptBin "tarlz"                   [ pkgs.gnutar pkgs.lzip ];
  tartar                  = writePatchedScriptBin "tartar"                  [ pkgs.gnutar ];
  tarxz                   = writePatchedScriptBin "tarxz"                   [ pkgs.gnutar pkgs.xz ];
  untar                   = writePatchedScriptBin "untar"                   [ pkgs.gnutar pkgs.p7zip pkgs.gzip pkgs.bzip2 pkgs.lzip pkgs.xz ];
  wm-sh                   = writePatchedScriptBin "wm.sh"                   [ pkgs.wmctrl pkgs.coreutils ];
}
