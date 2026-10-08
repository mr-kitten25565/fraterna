# Fraterna

A flake that wraps [Pumpkin](https://github.com/Pumpkin-MC/Pumpkin) with RFC 42 `settings` and a declarative list of WASM plugin derivations.

This is a Nix stand-in for installing plugins into `plugins/` (what `ppm install` does). It does not search the marketplace or scaffold new plugins.

Pumpkin reads `pumpkin.toml` from the process working directory and writes worlds and logs there. The wrapper copies config and links plugins into `$PUMPKIN_DATA_DIR` (or `$PWD`) on each start, then `cd`s there.

## Usage

```nix
{
  inputs.fraterna.url = "path:../fraterna"; # or a git URL
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
            package = helloWorld; # derivation with passthru.pumpkinPlugin.name
            settings.greeting = "from nix";
          }
        ];
      };
    };
}
```

Run:

```bash
PUMPKIN_DATA_DIR=./data nix run
```

### Options

- `package` — Pumpkin derivation to wrap.
- `settings` — attrset serialized to `pumpkin.toml`. Freeform; a few plugin keys have defaults (`enabled`, `allow_unsigned`, `verify_signatures = false`, `ask_permission_confirmation = false`, `hot_reload = false`).
- `plugins` — list of packages or `{ package, name?, wasmName?, settings?, files? }`. Each `.wasm` is linked to `plugins/<name>.wasm`. `settings` is written to `plugins/data/<name>/config.toml`. `files` copies extra paths into that data directory (for example PLua's `config.json` and `plugins/*.lua`).
- `dataDirEnv` — env var for the writable server dir (default `PUMPKIN_DATA_DIR`).

Plugin packages should install `$out/<name>.wasm` and set `passthru.pumpkinPlugin.name`.
