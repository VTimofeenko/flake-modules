# flake module that brings in the deployment commands
{ flake-parts-lib
, lib
, deploy-rs
, ...
}:
let
  inherit (flake-parts-lib) mkPerSystemOption;
  inherit (lib) mkEnableOption;
in
{ lib, self, ... }:
let
  /* Attrset of lists of devshell commands. Output of this module. */
  allCommands =
    { pkgs
    , useDeployRs ? false
    , system
    , ...
    }:
    let
      /* Builds a derivation and then turns its main executable into a string.

      Used for devshell commands */
      commandBuildHelper = attrset: builtins.readFile (pkgs.lib.getExe (with pkgs; writeShellApplication attrset));
      /* Constructs a devShell command for a provided category. Prefixes the command and supplies category. */
      mkCommandCategory = category: { help, name, command }: {
        name = "${category}-${name}";
        inherit help command category;
      };
    in
    builtins.concatLists
      (builtins.attrValues
        (builtins.mapAttrs
          (name: value: map (mkCommandCategory name) value)
          {
            /* Deployment commands for all nixosConfigurations and for the local machine.

            The local machine deployment command is aware of running on something other than NixOS and will fall back on home-manager.
            */
            deploy =
              let
                mkCmd = machineName:
                  if useDeployRs
                  then
                    "${deploy-rs.packages.${system}.default} -s \${PRJ_ROOT}#${machineName}"
                  else "nixos-rebuild --flake \${PRJ_ROOT}#${machineName} --target-host root@${machineName}.home.arpa switch";
                machines =
                  if useDeployRs then
                    (self.deploy.nodes or (lib.warn "No deploy.nodes specified in the flake.nix, using empty list" [ ]))
                  else self.nixosConfigurations;
              in
              (map
                (machineName: {
                  help = "Deploy remote ${machineName}";
                  name = "${machineName}"; # 'deploy-' prefix will be added automatically
                  command = mkCmd machineName;
                })
                (builtins.attrNames machines)) ++
              [
                {
                  help = "Deploy the flake on this machine";
                  name = "local";
                  command =
                    # bash
                    ''
                      if [[ $(grep -s ^NAME= /etc/os-release | sed 's/^.*=//') == "NixOS" ]]; then
                        sudo nixos-rebuild switch --flake ''${PRJ_ROOT} # PRJ_ROOT is set <=> we're in direnv. Prevents extra warnings
                      else # Not a NixOS machine
                       home-manager switch --flake ''${PRJ_ROOT}
                      fi'';
                }
              ];
            ci = [
              {
                help = "Build all packages";
                name = "build-all";
                # Command needs to be a string
                command = commandBuildHelper {
                  name = "build-all";
                  runtimeInputs = [ pkgs.jq ];
                  text = builtins.readFile ./assets/build-all.sh;
                };
              }
              {
                help = "Lint all the code. Managed through pre-commit.";
                name = "lint-all";
                command = ''
                  nix develop .#pre-commit --command bash -c "pre-commit run --all-files"'';
              }
              {
                help = "Run all tests";
                name = "test-all";
                command =
                  # bash
                  ''
                    echo "not implemented"
                    exit 1
                  '';
              }
            ];
            general = [ ];
          })); # // { all = builtins.concatLists (builtins.attrValues allCommands); };
in
{
  options.perSystem = mkPerSystemOption ({ config, pkgs, system, ... }: {
    options.deployCmds.useDeployRs = mkEnableOption "deploy-rs support";
    config.devshells.default =
      {
        env = [ ];
        commands = allCommands { inherit pkgs system; inherit (config.deployCmds) useDeployRs; };
        packages = [ ];
      };
  });
  # TODO: auto-generate flake.deploy.nodes output
}

