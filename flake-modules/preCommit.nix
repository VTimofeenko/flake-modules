# flake module that configures pre-commit hooks environment
{ flake-parts-lib, ... }:
let
  inherit (flake-parts-lib) mkPerSystemOption;
in
_: {
  # NOTE: this approach makes the configuration composable with whatever a downstream flake defines

  options.perSystem = mkPerSystemOption (
    { config, pkgs, ... }:
    {
      config =
        let
          # Parses deadnix output into vim quickfix
          deadnix-quickfix = pkgs.writeShellApplication {
            name = "deadnix-quickfix";
            runtimeInputs = [ pkgs.jq ];
            text = ''
              ${config.pre-commit.settings.hooks.deadnix.entry} -o json | jq -r '.file as $file | .results[] | "\($file):\(.line):\(.column): \(.message)"'
            '';
          };
          statix-quickfix = pkgs.writeShellApplication {
            name = "statix-quickfix";
            runtimeInputs = [ pkgs.jq ];
            text = ''
              ORIG="${config.pre-commit.settings.hooks.statix.entry}"

              # Somewhat of a hack to replace whatever format was specified with json
              CMD=''${ORIG/${config.pre-commit.settings.hooks.statix.settings.format}/json}

              # Eval is needed, otherwise some escaping shenanigans happen and direnv is not ignored
              eval "$CMD" | jq -r '.file as $file | .report[] | .note as $note | .diagnostics[] | "\($file):\(.at.from.line):\(.at.from.column): \($note)"'
            '';
          };
        in
        {
          # TODO: make easier to compose with default nix shell. Use lib.mkMerge?
          devShells.pre-commit = config.pre-commit.devShell;
          pre-commit.settings = {
            hooks = {
              treefmt.enable = true;
              deadnix.enable = true;
              statix = {
                enable = true;
                settings = {
                  ignore = [ ".direnv/" ];
                  format = "stderr";
                };
              };
            };
            settings = {
              treefmt.package = config.treefmt.build.wrapper;
            };
          };
          # Add a command to install the hooks
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
            packages =
              (builtins.attrValues { inherit (config.pre-commit.pkgs) statix deadnix; })
              ++ [ config.pre-commit.settings.package ]
              ++ [
                deadnix-quickfix
                statix-quickfix
              ];
          };
        };
    }
  );
}
