package builder

import (
	"github.com/hashicorp/waypoint/builtin/docker"
  "google.golang.org/protobuf/types/known/emptypb"
)

func NixImageMapper(src *DockerImage) *docker.Image {
	return &docker.Image{
		Image: src.Image,
		Tag:   src.Tag,
    Location: &docker.Image_Docker{ Docker: &emptypb.Empty{} },
	}
}
