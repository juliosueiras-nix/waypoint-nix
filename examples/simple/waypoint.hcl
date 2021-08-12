project = "simple-nix"

app "web" {
  build {
    use "nix" {
      image = "simple-python"
      tag   = "latest"
    }
  }

  deploy {
    use "docker" {}
  }
}
