{
  description = "My flake modules";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixpkgs-lib.url = "github:NixOS/nixpkgs/nixos-unstable?dir=lib";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs-lib";

    pre-commit-hooks-nix = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    };
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs-unstable";

    # treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.url = "github:VTimofeenko/treefmt-nix?ref=nickel-syntax-fix"; # TODO: move back once #133 is merged upstream
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs-unstable";

  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; }
      ({ withSystem, flake-parts-lib, ... }:
        let
          inherit (inputs.nixpkgs-lib) lib;# A faster way to propagate lib to certain modules
          inherit (flake-parts-lib) importApply;
          flake-modules = {
            devShellCmds = importApply ./flake-modules/devShellCmds {
              inherit flake-parts-lib lib;
              inherit (inputs) deploy-rs;
            };
            precommitHooks = importApply ./flake-modules/preCommit.nix { inherit flake-parts-lib; };
            inputsBumper = importApply ./flake-modules/bumpInputs.nix { inherit withSystem lib flake-parts-lib; };
            mkHomeManagerOutputMerge = import ./flake-modules/mkHomeManagerOutputsMerge.nix;
            formatters = importApply ./flake-modules/formatters.nix { inherit withSystem flake-parts-lib lib; };
          };
        in
        {
          imports = builtins.concatLists [
            [
              # Non-local inputs
              inputs.devshell.flakeModule
              inputs.pre-commit-hooks-nix.flakeModule
              inputs.treefmt-nix.flakeModule
            ]
            [
              flake-modules.devShellCmds
              flake-modules.precommitHooks
              flake-modules.mkHomeManagerOutputMerge
              flake-modules.formatters
            ]
          ];
          systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
          flake = {
            inherit flake-modules;
          };
        });
}
