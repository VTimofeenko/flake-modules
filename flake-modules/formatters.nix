# This file configures treefmt
# By default -- only configures nixpkgs-fmt as my go-to nix formatter
# TODO: add the options for languages
# TODO: add integrate with this pre-commit option
{ withSystem, ... }:
{
  perSystem = { system, ... }: {
    treefmt.programs = withSystem system (_: {
      nixpkgs-fmt.enable = true;
      # black.enable # Maybe
      # deadnix.enable # maybe
      # dprint.enable # Maybe? Like prettierrc
      # gofmt.enable # Maybe
      # hclfmt.enable # Maybe
      # isort.enable # Maybe
      # mdformat.enable # Maybe
      # nickel.enable # Maybe
      # prettier.enable # Maybe
      # ruff.enable # Maybe
      # rustfmt.enable # Maybe
      # scalafmt.enable # Maybe
      # shellcheck.enable # Maybe
      # statix.enable # Maybe, dup
      # stylua.enable # Maybe
      # terraform.enable # Maybe
      # yamlfmt.enable # Maybe
    });
    treefmt.projectRootFile = "flake.nix";
    /* Add configured treefmt to the default devshell */
    devshells.default = withSystem system ({ config, ... }: {
      packages = [
        config.treefmt.build.wrapper # Pull in pre-configured treefmt
      ];
    });
  };
}
