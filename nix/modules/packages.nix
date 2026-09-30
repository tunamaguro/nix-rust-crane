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

      flamegraph = app.override {
        profile = "flamegraph";
        dontStrip = true;
        # perf needs --no-rosegment for accurate stacks with lld/mold on Linux.
        rustFlags =
          "-C force-frame-pointers=yes"
          + lib.optionalString pkgs.stdenv.hostPlatform.isLinux " -C link-arg=-Wl,--no-rosegment";
      };

      flamegraphRunner = pkgs.writeShellApplication {
        name = "profile-flamegraph";
        text = ''
          # Options before -- belong to flamegraph; the rest go to the program.
          profiler_args=()
          while (( $# > 0 )); do
            if [[ "$1" == -- ]]; then
              shift
              break
            fi
            profiler_args+=("$1")
            shift
          done
          exec ${lib.getExe' pkgs.cargo-flamegraph "flamegraph"} \
            "''${profiler_args[@]}" -- ${lib.getExe config.packages.flamegraph} "$@"
        '';
      };

      mkFlakeApp = package: {
        type = "app";
        program = lib.getExe package;
      };
    in
    {
      packages = {
        default = release;
        inherit debug release flamegraph;
      };

      apps = {
        default = mkFlakeApp config.packages.debug;
        debug = mkFlakeApp config.packages.debug;
        release = mkFlakeApp config.packages.release;
        flamegraph = mkFlakeApp flamegraphRunner;
      };
    };
}
