{ lib, config, options, pkgs, ... }:

let
  cfg = config.programs.foo;
in

{
  imports =
    [
      # import other modules here
    ];

  options.programs.foo = {
    enable = mkEnableOption "the foo program";

    package = mkOption {
      type        = types.package;
      default     = pkgs.hello;
      defaultText = literalExpression "pkgs.hello";
      description = "foo package to use.";
    };

    extraConfig = mkOption {
      default     = "";
      example     = ''
        foo bar
      '';
      type        = types.lines;
      description = ''
        Extra settings for foo.
      '';
    };
  };

  config = mkIf cfg.enable {

    assertions = [
      {
        assertion = condition-that-must-be-true;
        message   = ''
          msg on condition failed
        '';
      }
    ];

    home.packages = [ cfg.package ];
    # ...
  };
}
