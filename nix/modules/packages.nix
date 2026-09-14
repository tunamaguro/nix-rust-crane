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
      mkPackage = import ../toolchain.nix { inherit inputs; };
      app = mkPackage pkgs;
      release = app.override {
        profile = "release";
        dontStrip = false;
      };

      debug = app.override {
        profile = "dev";
        dontStrip = true;
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
        default = mkFlakeApp config.packages.debug;
        debug = mkFlakeApp config.packages.debug;
        release = mkFlakeApp config.packages.release;
      };
    };
}
