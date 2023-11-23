# This file configures treefmt
# By default -- only configures nixpkgs-fmt as my go-to nix formatter
# TODO: Add option to add languages to devshell
{ flake-parts-lib
, lib
, ...
}:
let
  inherit (flake-parts-lib) mkPerSystemOption;
  inherit (lib) mkOption types;
in
_:
{
  options.perSystem = mkPerSystemOption ({ config, ... }: {
    options.formatters = mkOption {
      type = with types; (listOf (enum [
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
    config.treefmt = {
      programs =
        let
          # enableIf :: str -> { enable: bool }
          #  
          # Returns a treefmt configuration attrset for a given option 
          # if the supplied string is present in the options.formatters
          enableIf = optionName: { enable = builtins.elem optionName config.formatters; };
        in
        {
          nixpkgs-fmt.enable = true; # Always on

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
        };
      projectRootFile = "flake.nix";
    };
    config.devshells.default.packages = [
      config.treefmt.build.wrapper # Pull in pre-configured treefmt
    ];

  });
}
