{
  lib,
  pkgs,
  crane,
  rustToolchainFor,
  crate ? null,
  profile ? "release",
  bin ? null,
  rustFlags ? null,
  doCheck ? false,
}:
let
  craneLib = crane.overrideToolchain rustToolchainFor;
  rustToolchain = rustToolchainFor pkgs;

  cargoExtraArgs = lib.concatStringsSep " " (
    [ "--locked" ]
    ++ lib.optionals (crate != null) [
      "-p"
      (lib.escapeShellArg crate)
    ]
    ++ lib.optionals (bin != null) [
      "--bin"
      (lib.escapeShellArg bin)
    ]
  );

  commonArgs = {
    src = craneLib.cleanCargoSource ../.;
    cargoLock = ../Cargo.lock;
    inherit cargoExtraArgs doCheck;

    env =
      {
        CARGO_PROFILE = profile;
      }
      // lib.optionalAttrs (rustFlags != null) {
        RUSTFLAGS = rustFlags;
      };
  }
  // lib.optionalAttrs (crate != null) {
    pname = crate;
  };

  cargoArtifacts = craneLib.buildDepsOnly commonArgs;

  crateInfo = craneLib.crateNameFromCargoToml {
    inherit (commonArgs) src;
  };

  mainProgram =
    if bin != null then
      bin
    else if crate != null then
      crate
    else
      crateInfo.pname;
in
craneLib.buildPackage (
  commonArgs
  // {
    inherit cargoArtifacts;

    passthru = {
      inherit
        cargoArtifacts
        commonArgs
        craneLib
        mainProgram
        rustToolchain
        ;

      buildConfig = {
        inherit
          bin
          crate
          profile
          rustFlags
          ;
      };
    };

    meta.mainProgram = mainProgram;
  }
)
