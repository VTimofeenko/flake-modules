{ pkgs, lib, ... }:
let
  inherit (import ./lib.nix { inherit pkgs lib; }) mkCommandCategory commandBuildHelper;
in
map (mkCommandCategory "ci") [
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
    command = ''nix develop ''${PRJ_ROOT}#pre-commit --command bash -c "pre-commit run --all-files"'';
  }
  # TODO: implement
  # {
  #   help = "Run all tests";
  #   name = "test-all";
  #   command =
  #     # bash
  #     ''
  #       echo "not implemented"
  #       exit 1
  #     '';
  # }
]
