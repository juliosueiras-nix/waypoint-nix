project = "simple-nix"

app "web" {
  build {
    use "nix" {
      image = "simple-python"
      tag   = "latest"
      nix_file = "./examples/simple/default.nix"
    }
  }

  deploy {
    use "docker" {}
  }
}
