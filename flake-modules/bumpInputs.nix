# flake module that adds commands to quickly bump and commit frequently changing inputs

{ lib, flake-parts-lib, ... }:
let
  inherit (flake-parts-lib) mkPerSystemOption;
  inherit (lib)
    mkOption
    types
    mkEnableOption
    optional
    assertMsg
    ;
in
{ self, inputs, ... }: # Consumer flake references
{
  options.perSystem = mkPerSystemOption (
    { config, pkgs, ... }:
    let
      cfg = config.bumpInputs;
    in
    {
      options.bumpInputs.changingInputs = mkOption {
        description = ''
          List of names of quickly changing inputs.

          This list will be turned into shell commands through devshell.
        '';
        type = types.listOf types.nonEmptyStr;
        default = [ ];
      };

      options.bumpInputs.bumpAllInputs = mkEnableOption "command to bump all inputs and commit";

      config.devshells.default =
        let
          bumpScript = pkgs.writeShellApplication {
            name = "bump-input";
            runtimeInputs = [ ];
            text = builtins.readFile ./assets/bump-input;
          };
        in
        {
          commands =
            (map (inputName: {
              help =
                # Double-check that the input actually exists
                # This is not strictly necessary as the wrapped nix flake does the same thing, but it's an illustration of referring to the consumer flake (self.inputs)
                assert assertMsg (builtins.elem inputName (
                  builtins.attrNames self.inputs
                )) "Input '${inputName}' does not exist in current flake. Check bumper settings.";
                "Bump input ${inputName}";
              name = "flake-bump-${inputName}"; # The name of the resulting script
              command = # bash
                "${pkgs.lib.getExe bumpScript} ${inputName}";
              category = "flake management";
            }) cfg.changingInputs)

            # Add a special case for bumping all inputs by handling the value of bumpAllInputs option
            ++ optional cfg.bumpAllInputs {
              help = "Bump all inputs";
              name = "flake-bump-all-inputs";
              command = # bash
                "${pkgs.lib.getExe bumpScript} \"*\"";
              category = "flake management";
            };
        };
    }
  );
}
