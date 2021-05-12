{
  description =
    "Waypoint-nix - A Waypoint Plugin to use Nix for building Docker Image";

  inputs.nixpkgs.url =
    "github:nixos/nixpkgs/1ac507ba981970c8e864624542e31eb1f4049751";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = { allowUnfree = true; };
        };
      in {
        packages.waypoint = pkgs.callPackage ./waypoint.nix {};

        packages.protoc-gen-go = pkgs.buildGo114Module {
          name = "protoc-gen-go";

          src = pkgs.fetchFromGitHub {
            owner = "golang";
            repo = "protobuf";
            rev = "v1.5.2";
            sha256 = "E/6Qh8hWilaGeSojOCz8PzP9qnVqNG2DQLYJUqN3BdY=";
          };

          subPackages = [ "./protoc-gen-go" ];

          doCheck = false;

          vendorSha256 = "CcJjFMslSUiZMM0LLMM3BR53YMxyWk8m7hxjMI9tduE=";
        };

        defaultPackage = pkgs.buildGo114Module {
          name = "waypoint-nix";

          src = pkgs.lib.sourceFilesBySuffices ./. [
            ".go"
            ".proto"
            ".sum"
            ".mod"
          ];

          preBuild = ''
            export PATH=$PATH:${self.packages."${system}".protoc-gen-go}/bin
            ${pkgs.protobuf}/bin/protoc -I . --go_out=plugins=grpc:. --go_opt=paths=source_relative ./builder/output.proto
          '';

          vendorSha256 = "hBMok0DS0/nkcs6BJ6lIMMbpQzaygv62iGDbfiKePz4=";

          postInstall = ''
            mv $out/bin/waypoint-nix $out/bin/waypoint-plugin-nix
          '';
        };

        devShell = pkgs.mkShell {
          NIX_PATH = "nixpkgs=${nixpkgs}";

          buildInputs =
            [
              pkgs.gopls pkgs.go_1_14 pkgs.protobuf self.packages."${system}".protoc-gen-go 
              self.packages."${system}".waypoint 
            ];
        };
      });
}
