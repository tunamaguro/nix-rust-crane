{
  description = "Rust + Nix template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    crane.url = "github:ipetkov/crane";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      imports = [
        flake-parts.flakeModules.partitions
      ];

      partitionedAttrs = {
        checks = "dev";
        devShells = "dev";
        formatter = "dev";
      };

      partitions.dev = {
        extraInputsFlake = ./nix/dev;

        module =
          { inputs, ... }:
          {
            imports = [
              inputs.treefmt-nix.flakeModule
              ./nix/modules/formatter.nix
            ];

            perSystem =
              { config, pkgs, ... }:
              let
                rustToolchainFor =
                  p:
                  (inputs.rust-overlay.lib.mkRustBin { } p).fromRustupToolchainFile ./rust-toolchain.toml;

                craneLib = (inputs.crane.mkLib pkgs).overrideToolchain rustToolchainFor;
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
    };
}
