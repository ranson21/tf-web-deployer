
locals {
  # Use provided token or fall back to environment variable
  github_token = coalesce(var.github_token, data.external.env.result.GITHUB_TOKEN)
}

# Read from environment variable
data "external" "env" {
  program = ["sh", "-c", "echo '{\"GITHUB_TOKEN\":\"'\"$GITHUB_TOKEN\"'\"}'"]
}

resource "terraform_data" "version" {
  input = var.release_version
}

resource "null_resource" "web_deployer" {
  triggers = {
    version = terraform_data.version.output
  }

  provisioner "local-exec" {
    command     = <<-EOT
      set -x  # Enable command tracing
      echo "Copying script..."
      cp ./files/get_release.sh ./get_release.sh || { echo "Copy failed with status $?"; ls -la ./files/get_release.sh; exit 1; }
      
      echo "Making script executable..."
      chmod +x ./get_release.sh || { echo "Chmod failed with status $?"; exit 1; }
      
      echo "Running script..."
      export GITHUB_TOKEN="$${GITHUB_TOKEN}"
      sh -x ./get_release.sh ${var.owner} ${var.repo} ${var.release_version} ${var.asset_name} || { echo "Script execution failed with status $?"; exit 1; }
    EOT
    interpreter = ["/bin/sh", "-c"]
    environment = {
      GITHUB_TOKEN = "oauth2:${local.github_token}"
    }
  }

  provisioner "local-exec" {
    command = "gsutil -m rsync -r -c -d release_contents/ gs://${var.bucket_name}"
  }

  provisioner "local-exec" {
    command = "rm -rf release_contents"
    when    = destroy
  }
}
