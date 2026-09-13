{ inputs, ... }:
pkgs:
let
  rustToolchainFor =
    p:
    (inputs.rust-overlay.lib.mkRustBin { } p).fromRustupToolchainFile ../rust-toolchain.toml;

  craneLib = (inputs.crane.mkLib pkgs).overrideToolchain rustToolchainFor;
in
{
  inherit rustToolchainFor craneLib;
}
