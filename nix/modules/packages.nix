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
      mkApp = (import ../toolchain.nix { inherit inputs; } pkgs);
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

      lint = pkgs.writeShellApplication {
        name = "lint";
        runtimeInputs = [ debug.passthru.rustToolchain ];
        text =
          let
            crate = debug.passthru.buildConfig.crate;
            crateArg = lib.optionalString (crate != null) "-p ${lib.escapeShellArg crate}";
          in
          ''
            exec cargo clippy --locked --fix --allow-dirty --allow-staged --all-targets ${crateArg} "$@"
          '';
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
        lint = {
          type = "app";
          program = lib.getExe lint;
        };
      };
    };
}
