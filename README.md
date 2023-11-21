These are a couple of flake modules to be used with [flake-parts](https://flake.parts/dogfood-a-reusable-module).

# Example

With a flake:
```nix
{
  # 1. Add to inputs
  inputs.my-flake-modules.url = "github:VTimofeenko/flake-modules";
  inputs.devshell.url = "github:numtide/devshell";
  inputs.pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";

  # 2. Import and configure
  outputs = _:
    flake-parts.lib.mkFlake {
      imports = with inputs; [
        devshell.flakeModule  # Dependency
        pre-commit-hooks-nix.flakeModule # Dependency
      ] ++ (builtins.attrValues inputs.my-flake-modules.flake-modules); # Shorthand for "import all of them"
      # ...
    perSystem = _: {
      # ... 
      changingInputs = [ "some-input" ];
    };
  };
}
```

A live example can be found at my [dotfiles config](https://github.com/VTimofeenko/monorepo-machine-config)

# Contents

* `devShellCmds` – creates CI commands that can be run at any time from the devshell.
* `precommitHooks` – contains my commonly used pre-commit configuration.
* `inputsBumper` – allows quickly bumping a version of a flake input and commit it
* `mkHomeManagerOutputMerge` – a meta module that allows composing homeManagerModules outputs like it happens with nixosModules
