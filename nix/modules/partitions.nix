{ inputs, ... }:
{
  imports = [
    inputs.flake-parts.flakeModules.partitions
  ];

  partitionedAttrs = {
    checks = "dev";
    devShells = "dev";
    formatter = "dev";
  };

  partitions.dev = {
    extraInputsFlake = ../dev;

    module =
      { inputs, ... }:
      {
        imports = [
          inputs.treefmt-nix.flakeModule
          ./formatter.nix
        ];

        perSystem =
          { config, pkgs, ... }:
          let
            inherit (import ../toolchain.nix { inherit inputs; } pkgs) craneLib;
          in
          {
            devShells.default = craneLib.devShell {
              packages = [
                config.treefmt.build.wrapper
              ];
            };
          };
      };
  };
}
