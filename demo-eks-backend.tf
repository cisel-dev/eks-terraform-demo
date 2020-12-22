terraform {
  backend "remote" {
    organization = "your-organization"

    workspaces {
      name = "your-workspace"
    }
  }
}
