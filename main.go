package main

import (
	"github.com/juliosueiras-nix/waypoint-nix/builder"
	sdk "github.com/hashicorp/waypoint-plugin-sdk"
)

func main() {
	sdk.Main(sdk.WithComponents(&builder.Builder{}), sdk.WithMappers(builder.NixImageMapper))
  
}
