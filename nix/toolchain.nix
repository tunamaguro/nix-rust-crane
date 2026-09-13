{ inputs, ... }:
pkgs:
let
  rustToolchainFor =
    p:
    (inputs.rust-overlay.lib.mkRustBin { } p).fromRustupToolchainFile ../rust-toolchain.toml;

  rustToolchain = rustToolchainFor pkgs;
in
pkgs.callPackage ./build.nix {
  crane = inputs.crane.mkLib pkgs;
  inherit rustToolchain rustToolchainFor;
}
