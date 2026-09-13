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
          # The dev partition is a separate flake-parts evaluation. Import the
          # package module here as well so dev-only modules can consume build
          # internals through config.packages.*.passthru without exporting the
          # partition's packages as top-level flake outputs.
          ./packages.nix
          inputs.treefmt-nix.flakeModule
          ./formatter.nix
          ./checks.nix
          ./devshells.nix
        ];
      };
  };
}
