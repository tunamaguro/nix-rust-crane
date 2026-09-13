{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      rustToolchain =
        (inputs.rust-overlay.lib.mkRustBin { } pkgs).fromRustupToolchainFile ../../rust-toolchain.toml;
    in
    {
      treefmt.programs = {
        rustfmt = {
          enable = true;
          package = rustToolchain;
          includes = [ "*.rs" ];
        };

        mdformat = {
          enable = true;
          includes = [ "*.md" ];
        };

        taplo = {
          enable = true;
          includes = [ "*.toml" ];
        };
      };
    };
}
