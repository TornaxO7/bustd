{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@ { flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; }
      {
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];

        perSystem = { self', pkgs, system, ... }: {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;

            overlays = with inputs; [
              rust-overlay.overlays.default
            ];
          };

          apps.default = {
            type = "app";
            program = self'.packages.default;
          };

          packages.default = pkgs.callPackage (import ./nix/package.nix) { };

          devShells.default =
            let
              rust-toolchain = pkgs.rust-bin.stable.latest.default.override {
                extensions = [ "rust-src" "rust-analyzer" ];
              };
            in
            pkgs.mkShell {
              packages = [ rust-toolchain ];
            };
        };

        flake =
          let
            cargoToml = builtins.fromTOML (builtins.readFile ./Cargo.toml);
            name = cargoToml.package.name;
            description = cargoToml.package.description;
          in
          {
            nixosModules = rec {
              default = bustd;
              bustd = { pkgs, config, lib, ... }:
                with lib;
                let
                  cfg = config.services.${name};
                  bustd-pkg = pkgs.callPackage (import ./nix/package.nix) { };
                in
                {
                  options.services.${name}.enable = mkEnableOption "Enable ${name}";

                  config = mkIf cfg.enable {
                    systemd.services.${name} = {
                      description = description;
                      wantedBy = [ "multi-user.target" ];
                      serviceConfig = {
                        ExecStart = "${lib.getExe bustd-pkg} --no-daemon";
                      };
                    };
                  };
                };
            };
          };
      };
}
