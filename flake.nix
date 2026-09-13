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

  outputs=inputs@{flake-parts,...}:
  flake-parts.lib.mkFlake{inherit inputs;}{
    systems=[  "aarch64-darwin"
  "aarch64-linux"
  "x86_64-darwin"
  "x86_64-linux"];
    imports=[];
    perSystem = {pkgs,...}:let
    rustToolchainFor =
      p:
      (inputs.rust-overlay.lib.mkRustBin { } p)
        .fromRustupToolchainFile ./rust-toolchain.toml;

    craneLib =
      (inputs.crane.mkLib pkgs).overrideToolchain rustToolchainFor;
    in
    {devShells.default=craneLib.devShell{
      packages=[];
      };};
  };
}
