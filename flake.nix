{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    wrappers.url = "github:nix-community/nix-wrapper-modules";
    wrappers.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        ./modules/parts.nix
      ];
    };
}
