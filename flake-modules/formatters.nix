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
                  pkgs-unstable.nickel
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
                (pkgs-unstable.nickel.overrideAttrs { meta.mainProgram = "nickel"; })
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
            Produces a python formatter with my commonly used parameters.

            Useful in case I have a scratch project where I don't bother with flake.nix or pyproject.toml

            Uses a combination of `ruff` and `black` with `ruff` doing the heavy lifting. `black` does a little better indenting code like this:

            ```
            f = fun("param1",
              "param2"
              )
            ```
          */
          my-python-formatter = pkgs.writeShellApplication {
            name = "i-dont-care-just-format-my-python-code-and-yell-at-me";
            runtimeInputs = [
              pkgs.ruff
              pkgs.black
            ];
            text =
              let
                settingsFormat = pkgs.formats.toml { };
                line-length = 120;
                ruffConfig = {
                  inherit line-length;
                  format.quote-style = "double";
                  lint = {
                    select = [
                      "A" # flake builtins
                      "D" # docstyle, very angry
                      "N" # pep8-naming
                      "TID" # for banned inputs
                      "Q" # quotes
                      "E111" # Indentation is not a multiple of {indent_size}
                      "E113" # Unexpected indentation
                      "E117" # Over-indented (comment)
                      "E201" # Whitespace after '{symbol}'
                      "E202" # Whitespace before '{symbol}'
                      "E203" # Whitespace before '{symbol}'
                      "E211" # Whitespace before '{bracket}'
                      "E221" # Multiple spaces before operator
                      "E222" # Multiple spaces after operator
                      "E225" # Missing whitespace around operator
                      "E226" # Missing whitespace around arithmetic operator
                      "E227" # Missing whitespace around bitwise or shift operator
                      "E228" # Missing whitespace around modulo operator
                      "E231" # Missing whitespace after '{token}'
                      "E241" # Multiple spaces after comma
                      "E242" # Tab after comma
                      "E251" # Unexpected spaces around keyword / parameter equals
                      "E252" # Missing whitespace around parameter equals
                      "E261" # Insert at least two spaces before an inline comment
                      "E262" # Inline comment should start with #
                      "E265" # Block comment should start with #
                      "E266" # Too many leading # before block comment
                      "E271" # Multiple spaces after keyword
                      "E272" # Multiple spaces before keyword
                      "E275" # Missing whitespace after keyword
                      "E301" # Expected {BLANK_LINES_NESTED_LEVEL:?} blank line, found 0
                      "E302" # Expected {expected_blank_lines:?} blank lines, found {actual_blank_lines}
                      "E303" # Too many blank lines ({actual_blank_lines})
                      "E304" # Blank lines found after function decorator ({lines})
                      "E305" # Expected 2 blank lines after class or function definition, found ({blank_lines})
                      "E306" # Expected 1 blank line before a nested definition, found 0
                      "E501" # Line too long ({width} > {limit})
                      "E703" # Statement ends with an unnecessary semicolon
                      "E711" # Comparison to None should be cond is None
                      "E712" # Avoid equality comparisons to True; use if {cond}: for truth checks
                      "E713" # Test for membership should be not in
                      "E714" # Test for object identity should be is not
                      "E721" # Do not compare types, use isinstance()
                      "E722" # Do not use bare except
                      "E999" # SyntaxError
                    ];
                    pydocstyle.convention = "pep257";
                  };
                };
              in
              ''
                set -x
                ruff check --config ${settingsFormat.generate "ruff.toml" ruffConfig} --fix --preview "$@"
                black --line-length 120 "$@"
              '';
          };
        }
      );
      checks = withSystem system (
        { pkgs, ... }:
        {
          test-python-formatter = pkgs.testers.runNixOSTest {
            name = "check-my-ruff-formatter-works";

            nodes.machine =
              { pkgs, ... }:
              {
                environment.systemPackages = [ self.packages.${pkgs.system}.my-python-formatter ];
              };

            testScript =
              # python
              ''
                print("AAA")
                file = "/tmp/test.py"
                docstring = "docstring"

                machine.execute(f"echo \"'{docstring}'\" > {file}")
                machine.execute(f"i-dont-care-just-format-my-python-code-and-yell-at-me {file}")

                result = machine.execute(f"cat {file}")
                assert result[1] == f"\"\"\"{docstring}\"\"\"\n", f"Something went wrong, got: {result} after ruff fix"
              '';
          };
        }
      );
    };
}
