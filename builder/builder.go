package builder

import (
	"context"
	"fmt"
  "os"
  "os/exec"
	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/waypoint-plugin-sdk/terminal"
	"github.com/docker/docker/pkg/jsonmessage"
	"github.com/hashicorp/waypoint-plugin-sdk/docs"
	"github.com/docker/docker/client"
	wpdockerclient "github.com/hashicorp/waypoint/builtin/docker/client"
)

type BuildConfig struct {
  // Optional Argument for -A to specify item in sets
	Argument string `hcl:"argument,optional"`

  // Target other nix file, default to default.nix
	NixFile string `hcl:"nix_file,optional"`

  // Loaded Docker image name, should be the same as the nix result one
	Image string `hcl:"image"`

  // Loaded Docker image tag, should be the same as the nix result one
	Tag string `hcl:"tag"`
}

type Builder struct {
	config BuildConfig
}

// Implement Configurable
func (b *Builder) Config() (interface{}, error) {
	return &b.config, nil
}

func (b *Builder) ConfigSet(config interface{}) error {
	_, ok := config.(*BuildConfig)
	if !ok {
		return fmt.Errorf("Expected *BuildConfig as parameter")
	}

	return nil
}

func (b *Builder) Documentation() (*docs.Documentation, error) {
	doc, err := docs.New(
		docs.FromConfig(&BuildConfig{}),
		docs.FromFunc(b.BuildFunc()),
	)

	if err != nil {
		return nil, err
	}

	doc.Description(`
Build a Docker from Nix files using nix-build

It will require nix-build to be pre-installed and available in PATH
`)

	doc.Example(`
build {
  use "nix" {
	  image  = "test"
	  tag    = "latest"
  }
}
`)

	doc.Input("component.Source")
	doc.Output("nix.Image")

  doc.SetField(
    "image",
    "Loaded Docker image name",
  )

  doc.SetField(
    "tag",
    "Loaded Docker image tag",
  )

  doc.SetField(
    "argument",
    "Argument for -A to sepcify item in sets",
  )

  doc.SetField(
    "nix_file",
    "Target nix file, default to default.nix",
  )

	return doc, nil
}

func (b *Builder) BuildFunc() interface{} {
	return b.build
}

func (b *Builder) build(ctx context.Context, ui terminal.UI, log hclog.Logger) (*DockerImage, error) {
  sg := ui.StepGroup()
  defer sg.Wait()
  step := sg.Add("Building Docker image with nix-build...")

  // Most of the functions below are borrowed from builtins' buildpack builder
	dockerClient, err := wpdockerclient.NewClientWithOpts(
		client.FromEnv,
		client.WithVersion("1.38"),
	)

	if err != nil {
		return nil, err
	}

  defer func() {
    if step != nil {
      step.Abort()
    }
  }()

  arguments := []string{b.config.NixFile}

  if b.config.Argument != "" {
    arguments = append(arguments, "-A", b.config.Argument)
  }
	
  cmd := exec.CommandContext(ctx, "nix-build", arguments...)

	cmd.Stdout = step.TermOutput()
	cmd.Stderr = cmd.Stdout

	if err := cmd.Run(); err != nil {
		return nil, err
	}

	step.Done()

  stepImport := sg.Add("Loading ./result into docker registry")

  f, err := os.Open("result")
  defer f.Close()

	if err != nil {
		return nil, err
	}

	stdout, _, err := ui.OutputWriters()
  resp, err := dockerClient.ImageLoad(ctx, f, false)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var termFd uintptr
	if f, ok := stdout.(*os.File); ok {
		termFd = f.Fd()
	}

	err = jsonmessage.DisplayJSONMessagesStream(resp.Body, stepImport.TermOutput(), termFd, true, nil)
	if err != nil {
		return nil, err
	}

	stepImport.Done()

	return &DockerImage{
    Image: b.config.Image,
    Tag: b.config.Tag,
  }, nil
}
