{inputs, ...}: {
  imports = [
    inputs.wrappers.flakeModules.wrappers
  ];

  config.flake.wrappers.pumpkin = {wlib, ...}: {
    imports = [./pumpkin/wrapper.nix];
  };

  config = {
    systems = [
      "aarch64-linux"
      "x86_64-linux"
    ];

    perSystem = {pkgs, ...}: {
      formatter = pkgs.nixfmt-rfc-style;
      wrappers.control_type = "exclude";
      wrappers.packages.pumpkin = true;
    };
  };
}
