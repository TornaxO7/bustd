{ rustPlatform, lib, ... }:
let
  cargoToml = builtins.fromTOML (builtins.readFile ../Cargo.toml);
in
rustPlatform.buildRustPackage rec
{
  pname = cargoToml.package.name;
  version = cargoToml.package.version;

  src = builtins.path {
    path = ../.;
  };

  cargoLock.lockFile = ../Cargo.lock;

  meta = {
    description = cargoToml.package.description;
    homepage = cargoToml.package.repository;
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
