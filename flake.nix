{
  description = "My flake modules";
  inputs = {
    nixpkgs.follows = "nixpkgs-unstable";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-lib.url = "github:NixOS/nixpkgs/nixos-unstable?dir=lib";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs-lib";

    # elisp formatter
    emacs-elisp-autofmt = {
      url = "git+https://codeberg.org/ideasman42/emacs-elisp-autofmt";
      flake = false;
    };

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

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  outputs =
    inputs@{ flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { withSystem, flake-parts-lib, ... }:
      let
        inherit (inputs.nixpkgs-lib) lib; # A faster way to propagate lib to certain modules
        inherit (flake-parts-lib) importApply;
        flake-modules = {
          devShellCmds = importApply ./flake-modules/devShellCmds {
            inherit flake-parts-lib lib;
            inherit (inputs) deploy-rs;
          };
          precommitHooks = importApply ./flake-modules/preCommit.nix { inherit flake-parts-lib; };
          inputsBumper = importApply ./flake-modules/bumpInputs.nix {
            inherit withSystem lib flake-parts-lib;
          };
          mkHomeManagerOutputMerge = import ./flake-modules/mkHomeManagerOutputsMerge.nix;
          formatters = importApply ./flake-modules/formatters.nix {
            inherit
              withSystem
              flake-parts-lib
              lib
              self
              ;
            inherit (inputs) nixpkgs-unstable;
          };
        };

        # Modules that are dogfed go here
        dogfood = {
          emacsElispAutofmt = importApply ./flake-modules/elispAutofmt {
            inherit
              flake-parts-lib
              lib
              withSystem
              self
              ;
            src = inputs.emacs-elisp-autofmt;
          };
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
            flake-modules.inputsBumper
          ]
          (builtins.attrValues dogfood)
        ];
        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
          "x86_64-darwin"
        ];
        perSystem = _: { bumpInputs.bumpAllInputs = true; };
        flake = {
          inherit flake-modules;
        };
      }
    );
}
