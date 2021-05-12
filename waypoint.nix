# ref: https://github.com/NixOS/nixpkgs/blob/935da7634f4a881280e2edcd5203797305742d7a/pkgs/applications/networking/cluster/waypoint/default.nix
{ lib, buildGoModule, fetchFromGitHub, go-bindata }:

buildGoModule rec {
  pname = "waypoint";
  version = "2021-05-11";

  src = fetchFromGitHub {
    owner = "hashicorp";
    repo = pname;
    rev = "dca533f0e2a36bbc8df6fa89fbfa475bb7f673e3";
    sha256 = "qdR2l7y9Mpq+BGIH2Hpu/BGTF07Qv6qMnvZBaYcv2x4=";
  };

  deleteVendor = true;
  vendorSha256 = "G1BZ5TOJq0qX6eDbtVEZfRpZr7YysUZjh+/BdqBWY44=";

  nativeBuildInputs = [ go-bindata ];

  # GIT_{COMMIT,DIRTY} filled in blank to prevent trying to run git and ending up blank anyway
  buildPhase = ''
    runHook preBuild
    make bin GIT_DESCRIBE="v${version}" GIT_COMMIT="" GIT_DIRTY=""
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -D waypoint $out/bin/waypoint
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    # `version` tries to write to ~/.config/waypoint
    export HOME="$TMPDIR"

    $out/bin/waypoint --help
    $out/bin/waypoint version | grep "CLI: v${version}"
    runHook postInstallCheck
  '';

  # Binary is static
  dontPatchELF = true;
  dontPatchShebangs = true;

  meta = with lib; {
    homepage = "https://waypointproject.io";
    changelog = "https://github.com/hashicorp/waypoint/blob/v${version}/CHANGELOG.md";
    description = "A tool to build, deploy, and release any application on any platform";
    longDescription = ''
      Waypoint allows developers to define their application build, deploy, and
      release lifecycle as code, reducing the time to deliver deployments
      through a consistent and repeatable workflow.
    '';
    license = licenses.mpl20;
    maintainers = with maintainers; [ winpat jk ];
    platforms = platforms.linux;
  };
}
