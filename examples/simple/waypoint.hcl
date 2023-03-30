project = "simple-nix"

app "web" {
  build {
    use "nix" {
      image = "simple-python"
      tag   = "latest"
      nix_file = "${path.app}/default.nix"
    }
  }

  deploy {
    use "docker" {}
  }
}
