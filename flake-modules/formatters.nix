# This file configures treefmt
# By default -- only configures nixpkgs-fmt as my go-to nix formatter
{
  flake-parts-lib,
  lib,
  nixpkgs-unstable,
  withSystem,
  self,
  ...
}:
let
  inherit (flake-parts-lib) mkPerSystemOption;
  inherit (lib)
    mkEnableOption
    mkOption
    types
    recursiveUpdate
    ;
in
_: {
  options.perSystem = mkPerSystemOption (
    {
      config,
      system,
      pkgs,
      ...
    }:
    let
      cfg = config.format-module;
      pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
    in
    {
      options.format-module = {
        languages = mkOption {
          type =
            with types;
            (listOf (enum [
              # "python" # TODO: test
              # "config"
              "nickel"
              # "go"
              # "hcl" # TODO: test
              # "terraform" # TODO: test
              "rust"
              # "markdown" # TODO: think
              "shell"
              "scala"
              "lua"
              # yaml # TODO: maybe?
              # prettier # TODO: needed?
            ]));
          description = "Which langs to pull in";
          default = [ ];
        };
        addFormattersToDevshell = mkEnableOption "if set -- adds the languages to the devshell programs";
      };
      config.treefmt = {
        programs =
          let
            # enableIf :: str -> { enable: bool }
            #
            # Returns a treefmt configuration attrset for a given option
            # if the supplied string is present in the options.formatters
            enableIf = optionName: { enable = builtins.elem optionName cfg.languages; };
          in
          recursiveUpdate
            {
              nixfmt.enable = true;

              nickel = enableIf "nickel";

              rustfmt = enableIf "rust";

              shellcheck = enableIf "shell";

              # black = enableIf "python";
              # ruff = enableIf "python";
              # isort = enableIf "python";

              # dprint = enableIf "config"

              # gofmt = enableIf "go"

              # hclfmt = enableIf "hcl"
              # terraform = enableIf "hcl"

              # mdformat = enableIf "markdown"

              scalafmt = enableIf "scala";

              # deadnix.enable # maybe, dup
              # statix.enable # Maybe, dup

              stylua = enableIf "lua";

              # yamlfmt = enableIf "yaml";

              # prettier = enableIf "prettier"
            }
            {
              # Certain formatters always write formatted code back into files breaking treefmt
              # This workaround uses md5sum to compare files before and after
              # If the sums differ -- do the actual write
              # This effectively runs the formatters twice and de-parallelizes them which is super suboptimal
              nickel.package = pkgs.writeShellApplication {
                name = "nickel-treefmt-wrapper";
                runtimeInputs = [
                  pkgs.nickel
                  pkgs.coreutils
                ];
                text = ''
                  set -x
                  shift
                  for file in "$@"; do
                    ORIG_MD5=$(md5sum "$file" | cut -d ' ' -f 1)
                    NEW_MD5=$(nickel format < "$file" | md5sum | cut -d ' ' -f 1)
                    if [ "$ORIG_MD5" != "$NEW_MD5" ]; then
                      nickel format "$file"
                    fi
                  done
                '';
              };
              nixfmt.package = pkgs.writeShellApplication {
                name = "nixfmt-rfc-style-treefmt-wrapper";
                runtimeInputs = [
                  pkgs-unstable.nixfmt-rfc-style
                  pkgs.coreutils
                ];
                text = ''
                  set -x
                  for file in "$@"; do
                    ORIG_MD5=$(md5sum "$file" | cut -d ' ' -f 1)
                    NEW_MD5=$(nixfmt < "$file" | md5sum | cut -d ' ' -f 1)
                    if [ "$ORIG_MD5" != "$NEW_MD5" ]; then
                      nixfmt "$file"
                    fi
                  done
                '';
              };
            };
        projectRootFile = "flake.nix";
      };
      config.devshells.default.packages =
        [
          config.treefmt.build.wrapper # Pull in pre-configured treefmt
        ]
        ++ (
          if cfg.addFormattersToDevshell then
            (
              builtins.attrValues config.treefmt.build.programs
              ++ lib.optionals (builtins.elem "nickel" cfg.languages) [
                (pkgs.nickel.overrideAttrs { meta.mainProgram = "nickel"; })
              ]
            )
          else
            [ ]
        );
    }
  );
  config.perSystem =
    { system, ... }:
    {
      packages = withSystem system (
        { pkgs, ... }:
        {
          /**
            Produces an output for ruff wrapped with my commonly used parameters.

            Useful in case I have a scratch project where I don't bother with flake.nix or pyproject.toml
          */
          ruff = pkgs.writeShellApplication {
            name = "ruff";
            runtimeInputs = [ pkgs.ruff ];
            text =
              let
                settingsFormat = pkgs.formats.toml { };
                ruffConfig = {
                  line-length = 120;
                  lint = {
                    select = [
                      "A" # flake builtins
                      "D" # docstyle, very angry
                      "N" # pep8-naming
                      "TID" # for banned inputs
                    ];
                    pydocstyle.convention = "pep257";
                  };
                };
              in
              ''
                ruff check --config ${settingsFormat.generate "ruff.toml" ruffConfig} "$@"
              '';
          };
        }
      );
      checks = withSystem system (
        { pkgs, ... }:
        {
          test-ruff = pkgs.testers.runNixOSTest {
            name = "check-my-ruff-formatter-works";

            nodes.machine =
              { pkgs, ... }:
              {
                environment.systemPackages = [ self.packages.${pkgs.system}.ruff ];
              };

            testScript =
              # python
              ''
                print("AAA")
                file = "/tmp/test.py"
                docstring = "docstring"

                machine.execute(f"echo \"'{docstring}'\" > {file}")
                machine.execute(f"ruff --fix {file}")

                result = machine.execute(f"cat {file}")
                assert result[1] == f"\"\"\"{docstring}\"\"\"\n", f"Something went wrong, got: {result} after ruff fix"
              '';
          };
        }
      );
    };
}
