{ flake-parts-lib
, lib
, deploy-rs # The input flake
, ...
}:
let
  inherit (flake-parts-lib) mkPerSystemOption;
  inherit (lib) mkEnableOption mkOption;
in
{ lib, self, ... }:
{
  options.perSystem = mkPerSystemOption ({ config, pkgs, system, ... }: {
    options.devshellCmds = {
      deployment =
        {
          enable = mkEnableOption "deployment devshell commands";
          useDeployRs = mkEnableOption "deploy-rs support";
          localDeployment = mkEnableOption "add deploy-local command";
          deploymentDomain = mkOption {
            type = lib.types.str;
            default = ".home.arpa";
            description = "domain to be appended to the host name";
          };
          # generateDeployNodes = mkEnableOption "Auto-populate flake.deploy.nodes output";
        };
    };

    config.devshells.default =
      {
        env = [ ];
        commands = # allCommands { inherit pkgs system; inherit (config.deployCmds) useDeployRs; };
          let
            mkDeployCmds = import ./deploy.nix {
              deploymentConfig = config.devshellCmds.deployment;
              inherit deploy-rs pkgs lib system self;
            };
            ciCmds = import ./ci.nix {
              inherit pkgs lib;
            };
          in
          mkDeployCmds ++ ciCmds;
        packages = [ ];
      };
  });
  # TODO: auto-generate flake.deploy.nodes output
  # TODO: separate out the deployment commands
  # TODO: ssh commands
}
