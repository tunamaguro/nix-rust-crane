{ inputs, ... }:
{
  perSystem =
    { config, ... }:
    let
      package = config.packages.release;
      inherit (package.passthru) craneLib commonArgs cargoArtifacts;
      src = commonArgs.src;
      checkArgs = commonArgs // { inherit cargoArtifacts; };
    in
    {
      checks = {
        build = package;

        fmt = craneLib.cargoFmt {
          inherit src;
        };

        clippy = craneLib.cargoClippy (
          checkArgs
          // {
            cargoClippyExtraArgs = "--all-targets -- --deny warnings";
          }
        );

        test = craneLib.cargoNextest (
          checkArgs
          // {
            doCheck = true;
            partitions = 1;
            partitionType = "count";
            cargoNextestPartitionsExtraArgs = "--no-tests=pass";
          }
        );

        audit = craneLib.cargoAudit {
          inherit src;
          advisory-db = inputs.advisory-db;
        };

        deny = craneLib.cargoDeny {
          inherit src;
        };
      };
    };
}
