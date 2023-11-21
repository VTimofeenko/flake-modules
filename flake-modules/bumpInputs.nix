# flake module that adds commands to quickly bump and commit frequently changing inputs
# WARN: Experimental, use at your own risk

{ lib, flake-parts-lib, ... }:
let
  inherit (flake-parts-lib) mkPerSystemOption;
  inherit (lib) mkOption types;
in

{
  options.perSystem = mkPerSystemOption ({ config, pkgs, ... }: {
    options.changingInputs = mkOption {
      description = ''
        List of names of quickly changing inputs.

        This list will be turned into shell commands through devshell.
      '';
      type = types.listOf types.str;
      default = [ ];
    };
    config.devshells.default =
      let
        bumpScript = pkgs.writeShellApplication {
          name = "bump-input";
          runtimeInputs = [ ];
          text = builtins.readFile ./assets/bump-input.sh;
        };
      in
      {
        commands =
          map
            (inputName: {
              help =
                # NOTE: this would somehow need access to outer args of the flake. self is not passed to the perSystem

                # Double-check that the input actually exists
                # assert builtins.elem inputName (builtins.attrNames self.inputs);
                "Bump input ${inputName}";
              name = "flake-bump-${inputName}";
              command = /* bash */ "${pkgs.lib.getExe bumpScript} ${inputName}";
              category = "flake management";
            })
            config.changingInputs;
      };
  });
}
