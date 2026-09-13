{ inputs, lib, ... }:
{
  perSystem =
    { config, pkgs, ... }:
    let
      cfg = config.rustBuild;
      inherit (import ../toolchain.nix { inherit inputs; } pkgs) craneLib;

      cargoExtraArgs = lib.concatStringsSep " " (
        [ "--locked" ]
        ++ lib.optionals (cfg.crate != null) [
          "-p"
          (lib.escapeShellArg cfg.crate)
        ]
        ++ lib.optionals (cfg.bin != null) [
          "--bin"
          (lib.escapeShellArg cfg.bin)
        ]
      );

      commonArgs = {
        src = craneLib.cleanCargoSource ../..;
        cargoLock = ../../Cargo.lock;
        inherit cargoExtraArgs;

        env = {
          CARGO_PROFILE = cfg.profile;
        }
        // lib.optionalAttrs (cfg.rustFlags != null) {
          RUSTFLAGS = cfg.rustFlags;
        };
      };

      cargoArtifacts = craneLib.buildDepsOnly commonArgs;
    in
    {
      options.rustBuild = {
        crate = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Cargo package to build with -p. Null leaves package selection to Cargo.";
        };

        profile = lib.mkOption {
          type = lib.types.str;
          default = "release";
          description = "Cargo profile used by Crane for dependency and package builds.";
        };

        bin = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Cargo binary target to build with --bin. Null leaves binary selection to Cargo.";
        };

        rustFlags = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Optional value exported as RUSTFLAGS for dependency and package builds.";
        };
      };

      config.packages.default = craneLib.buildPackage (
        commonArgs
        // {
          inherit cargoArtifacts;
        }
      );
    };
}
