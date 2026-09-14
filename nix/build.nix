{
  lib,
  pkgs,
  crane,
  rustToolchainFor,
  cargoPackage ? null,
  profile ? "release",
  bin ? null,
  pname ? null,
  cargoBuildExtraArgs?null,
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
    inherit cargoBuildExtraArgs doCheck dontStrip;

    env =
      {
        CARGO_PROFILE = profile;
      }
      // lib.optionalAttrs (rustFlags != null) {
        RUSTFLAGS = rustFlags;
      };
  };

  cargoArtifacts = craneLib.buildDepsOnly commonArgs;

  packageCargoExtraArgs = lib.escapeShellArgs (
    [ "--locked" ]
    ++ lib.optionals (cargoPackage != null) [
      "-p"
      cargoPackage
    ]
  );

  packageCargoBuildExtraArgs = lib.escapeShellArgs (
  [cargoBuildExtraArgs]++
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
      pname = resolvedPname;
      cargoExtraArgs = packageCargoExtraArgs;
      cargoBuildExtraArgs = packageCargoBuildExtraArgs;
    }
   ;
in
craneLib.buildPackage (
  packageArgs
  // {
    passthru = {
      inherit
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
