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

      flamegraphRustFlags =
        "-C force-frame-pointers=yes"
        + lib.optionalString pkgs.stdenv.hostPlatform.isLinux " -C link-arg=-Wl,--no-rosegment";

      flamegraph = app.override {
        profile = "flamegraph";
        dontStrip = true;
        doInstallCargoArtifacts = true;
        rustFlags = flamegraphRustFlags;
      };

      flamegraphRunner = pkgs.writeShellApplication {
        name = "profile-flamegraph";

        runtimeInputs = [
          flamegraph.passthru.rustToolchain
          pkgs.bash
          pkgs.cargo-flamegraph
          pkgs.coreutils
          pkgs.findutils
          pkgs.gnutar
          pkgs.rsync
          pkgs.zstd
        ];

        excludeShellChecks = [ "SC1091" ];

        text = ''
          export CARGO_TARGET_DIR="''${CARGO_TARGET_DIR:-$PWD/target}"
          export RUSTFLAGS=${lib.escapeShellArg flamegraphRustFlags}

          # inheritCargoArtifacts supports both compressed and directory artifacts.
          # Keep this defined because the directory code path references it directly.
          export doNotLinkInheritedArtifacts=""

          mkdir -p "$CARGO_TARGET_DIR"

          # makeSetupHook installs the Crane helper here. At runtime we only need
          # the inheritCargoArtifacts function, not its postPatch hook registration.
          source ${flamegraph.passthru.craneLib.inheritCargoArtifactsHook}/nix-support/setup-hook >/dev/null

          artifact=${lib.escapeShellArg (toString flamegraph)}
          marker="$CARGO_TARGET_DIR/.crane-flamegraph-artifact"

          # Seed the writable local target directory once per Nix artifact.
          # A changed source/toolchain/profile changes the store path and causes
          # the new artifact set to be inherited on the next invocation.
          if [[ ! -f "$marker" ]] || [[ "$(<"$marker")" != "$artifact" ]]; then
            inheritCargoArtifacts "$artifact" "$CARGO_TARGET_DIR"
            printf '%s\n' "$artifact" > "$marker"
          fi

          exec cargo flamegraph --profile flamegraph "$@"
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
