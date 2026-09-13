{ inputs, ... }:
{
  perSystem =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      mkApp = (import ../toolchain.nix { inherit inputs; } pkgs).override {
        crate = "nix-rust-crane";
        bin = "nix-rust-crane";
        rustFlags = null;
      };

      release = mkApp.override {
        profile = "release";
      };

      debug = mkApp.override {
        profile = "dev";
      };

      mkFlakeApp = package: {
        type = "app";
        program = lib.getExe package;
      };
    in
    {
      packages = {
        default = release;
        inherit debug release;
      };

      apps = {
        default = mkFlakeApp config.packages.release;
        debug = mkFlakeApp config.packages.debug;
        release = mkFlakeApp config.packages.release;
      };
    };
}
