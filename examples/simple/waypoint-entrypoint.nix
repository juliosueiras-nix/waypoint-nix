# adapted from https://github.com/nixos/nixpkgs/blob/master/pkgs/applications/networking/cluster/waypoint/default.nix
{ lib, buildGoModule, fetchFromGitHub, go-bindata, installShellFiles }:

buildGoModule rec {
  pname = "waypoint";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "hashicorp";
    repo = pname;
    rev = "v${version}";
    sha256 = "WKnidEYPtEDBJelQNSK30JqwT24oF8HKRZ0iyyNqdEM=";
  };

  vendorSha256 = "J1n6NgbLKi2aohm0OBzKJM/se/M/kHX0NFQWcitHotU=";

  nativeBuildInputs = [ go-bindata installShellFiles ];

  # GIT_{COMMIT,DIRTY} filled in blank to prevent trying to run git and ending up blank anyway
  buildPhase = ''
    runHook preBuild
    make bin bin/entrypoint GIT_DESCRIBE="v${version}" GIT_COMMIT="" GIT_DIRTY=""
    runHook postBuild
  '';

  doCheck = false;

  installPhase = ''
    install -D waypoint-entrypoint $out/bin/waypoint-entrypoint
  '';

  # Binary is static
  dontPatchELF = true;
  dontPatchShebangs = true;
}
