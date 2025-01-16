
locals {
  # Use provided token or fall back to environment variable
  github_token = coalesce(var.github_token, data.external.env.result.GITHUB_TOKEN)
}

# Read from environment variable
data "external" "env" {
  program = ["sh", "-c", "echo '{\"GITHUB_TOKEN\":\"'\"$GITHUB_TOKEN\"'\", \"FIREBASE_TOKEN\":\"'\"$FIREBASE_TOKEN\"'\"}'"]
}

resource "terraform_data" "version" {
  input = var.release_version
}

# GCS Deployer
resource "null_resource" "gcs_deployer" {
  count = var.host == "gcs" ? 1 : 0

  triggers = {
    version = terraform_data.version.output
  }

  provisioner "local-exec" {
    command     = <<-EOT
      echo "Copying script..."
      cp ./files/get_release.sh ./get_release.sh || { echo "Copy failed with status $?"; ls -la ./files/get_release.sh; exit 1; }

      echo "Making script executable..."
      chmod +x ./get_release.sh || { echo "Chmod failed with status $?"; exit 1; }

      echo "Running script..."
      sh -x ./get_release.sh ${var.owner} ${var.repo} ${var.release_version} ${var.asset_name} || { echo "Script execution failed with status $?"; exit 1; }

      echo "Running GCS deployment..."
      gsutil -m rsync -r -c -d release_contents/ gs://${var.bucket_name}
    EOT
    interpreter = ["/bin/sh", "-c"]
    environment = {
      GITHUB_TOKEN = local.github_token
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -rf release_contents"
  }
}

# Firebase Deployer
resource "null_resource" "firebase_deployer" {
  count = var.host == "firebase" ? 1 : 0

  triggers = {
    version = terraform_data.version.output
  }

  provisioner "local-exec" {
    command     = <<-EOT
      echo "Copying script..."
      cp ./files/get_release.sh ./get_release.sh || { echo "Copy failed with status $?"; ls -la ./files/get_release.sh; exit 1; }

      echo "Making script executable..."
      chmod +x ./get_release.sh || { echo "Chmod failed with status $?"; exit 1; }

      echo "Cloning repo..."
      git clone https://github.com/${var.owner}/${var.repo}.git repo
      cd repo

      echo "Running script..."
      sh -x ../get_release.sh ${var.owner} ${var.repo} ${var.release_version} ${var.asset_name} || { echo "Script execution failed with status $?"; exit 1; }

      echo "Running Firebase deployment..."
      mv release_contents dist
      npm install -g firebase-tools
      firebase deploy --only hosting
    EOT
    interpreter = ["/bin/sh", "-c"]
    environment = {
      GITHUB_TOKEN = local.github_token
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -rf release_contents repo"
  }
}
