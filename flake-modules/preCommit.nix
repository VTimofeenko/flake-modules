# flake module that configures pre-commit hooks environment
{ flake-parts-lib
, ...
}:
let
  inherit (flake-parts-lib) mkPerSystemOption;
in
_:
{
  # NOTE: this approach makes the configuration composable with whatever a downstream flake defines

  options.perSystem = mkPerSystemOption ({ config, pkgs, ... }:
    {
      config = {
        # TODO: make easier to compose with default nix shell. Use lib.mkMerge?
        devShells.pre-commit = config.pre-commit.devShell;
        pre-commit.settings = {
          hooks = {
            treefmt.enable = true;
            deadnix.enable = true;
            statix.enable = true;
          };
          settings = {
            statix.ignore = [ ".direnv/" ];
            statix.format = "stderr";
            treefmt.package = config.treefmt.build.wrapper;
          };
        };
        /* Add a command to install the hooks */
        devshells.default = {
          env = [ ];
          commands = [
            {
              help = "Install pre-commit hooks";
              name = "setup-pre-commit-install";
              command = ''nix develop ''${PRJ_ROOT}#pre-commit --command bash -c "exit"'';
              category = "setup";
            }
          ];
          # For manual checks
          packages = builtins.attrValues {
            inherit (pkgs) statix deadnix pre-commit;
          };
        };
      };
    });
}
