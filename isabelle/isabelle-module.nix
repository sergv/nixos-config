{
  pkgs,
  ...
}:
let
  mk-isabelle =
    include-emacs-lsp-fixes:
    import ./isabelle.nix {
      inherit pkgs include-emacs-lsp-fixes;
    };

  isabelle-pkg = mk-isabelle false;

  isabelle-lsp-pkg = mk-isabelle true;

  isabelle-lsp-wrapper =
    pkgs.runCommand "isabelle-emacs-lsp"
      {
        buildInptus = [ isabelle-lsp-pkg ];
        nativeBuildInputs = [ ];
      }
      ''
        mkdir -p "$out/bin"
        ln -s "${isabelle-lsp-pkg}/bin/isabelle" "$out/bin/isabelle-emacs-lsp"
      '';
in
{
  home.packages = [
    isabelle-pkg
    isabelle-lsp-wrapper
  ];
}
