# This file configures treefmt
# By default -- only configures nixpkgs-fmt as my go-to nix formatter
{
  flake-parts-lib,
  lib,
  nixpkgs-unstable,
  ...
}:
let
  inherit (flake-parts-lib) mkPerSystemOption;
  inherit (lib) mkEnableOption mkOption types;
in
_: {
  options.perSystem = mkPerSystemOption (
    { config, system, ... }:
    let
      cfg = config.format-module;
      pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
    in
    {
      options.format-module = {
        languages = mkOption {
          type =
            with types;
            (listOf (
              enum [
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
              ]
            ));
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
          {
            nixfmt = {
              enable = true;
              package = pkgs-unstable.nixfmt-rfc-style;
            };

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
      config.devshells.default.packages =
        [
          config.treefmt.build.wrapper # Pull in pre-configured treefmt
        ]
        ++ (
          if cfg.addFormattersToDevshell then (builtins.attrValues config.treefmt.build.programs) else [ ]
        );
    }
  );
}
