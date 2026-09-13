{
  lib,
  pkgs,
  crane,
  rustToolchainFor,
  cargoPackage ? null,
  profile ? "release",
  bin ? null,
  pname ? null,
  rustFlags ? null,
  doCheck ? true,
  dontStrip ? false,
}:
let
  craneLib = crane.overrideToolchain rustToolchainFor;
  rustToolchain = rustToolchainFor pkgs;

  commonArgs = {
    src = craneLib.cleanCargoSource ../.;
    cargoLock = ../Cargo.lock;
    strictDeps = true;
    inherit doCheck dontStrip;

    env =
      {
        CARGO_PROFILE = profile;
      }
      // lib.optionalAttrs (rustFlags != null) {
        RUSTFLAGS = rustFlags;
      };
  };

  artifactArgs =
    commonArgs
    // {
      cargoExtraArgs = "--locked --workspace";
      # Keep dev/test dependencies in the shared workspace artifact set even
      # when a final package explicitly disables its own checks.
      doCheck = true;
    };

  cargoArtifacts = craneLib.buildDepsOnly artifactArgs;

  packageCargoExtraArgs = lib.escapeShellArgs (
    [ "--locked" ]
    ++ lib.optionals (cargoPackage != null) [
      "-p"
      cargoPackage
    ]
  );

  cargoBuildExtraArgs = lib.escapeShellArgs (
    lib.optionals (bin != null) [
      "--bin"
      bin
    ]
  );

  crateInfo = craneLib.crateNameFromCargoToml {
    inherit (commonArgs) src;
  };

  resolvedPname =
    if pname != null then
      pname
    else if cargoPackage != null then
      cargoPackage
    else
      crateInfo.pname;

  resolvedMainProgram =
    if bin != null then
      bin
    else if cargoPackage != null then
      cargoPackage
    else
      crateInfo.pname;

  packageArgs =
    commonArgs
    // {
      inherit cargoArtifacts;
      cargoExtraArgs = packageCargoExtraArgs;
      pname = resolvedPname;
    }
    // lib.optionalAttrs (cargoBuildExtraArgs != "") {
      inherit cargoBuildExtraArgs;
    };
in
craneLib.buildPackage (
  packageArgs
  // {
    passthru = {
      inherit
        artifactArgs
        cargoArtifacts
        commonArgs
        craneLib
        rustToolchain
        ;
      mainProgram = resolvedMainProgram;
    };

    meta.mainProgram = resolvedMainProgram;
  }
)
