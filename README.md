# Fraterna

A flake that wraps [Pumpkin](https://github.com/Pumpkin-MC/Pumpkin) with `settings` and a declarative list of WASM plugin derivations.

This is a Nix stand-in for installing plugins into `plugins/` (what `ppm install` does). It does not search the marketplace or scaffold new plugins.

## Usage

```nix
{
  inputs.fraterna.url = "github:mr-kitten25565/fraterna";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { fraterna, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages.${system}.default = fraterna.wrappers.pumpkin.wrap {
        inherit pkgs;
        package = pkgs.pumpkin-mc; # any pumpkin derivation
        settings = {
          networking.java.online_mode = false;
          networking.java.encryption = false;
          networking.java.address = "0.0.0.0:25565";
        };
        plugins = [
          {
            package = helloWorld;
            settings.greeting = "from nix";
          }
        ];
      };
    };
}
```

Run:

```bash
nix run
```

## TODO

- PLua plugins: accept Lua scripts as wrap entries (data under `plugins/data/plua/plugins/` plus `enabled_plugins` in `config.json`) instead of `files` on the PLua package.
- Unlink Store paths after use. If you add a plugin, run the server than remove the plugin it will stay linked and will still be used.

