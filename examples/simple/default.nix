with import <nixpkgs> {};

let
  waypointEntrypoint = callPackage ./waypoint-entrypoint.nix {};
in dockerTools.buildImage {
  name = "simple-python";
  tag = "latest";

  config = {
    Entrypoint = [ 
      "${waypointEntrypoint}/bin/waypoint-entrypoint"
      "${python2}/bin/python2" "-m" "SimpleHTTPServer" "3000"
    ];
  };
}
