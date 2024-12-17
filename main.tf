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
      pwd
      echo "Files directory contents:"
      ls -la ./files/
      
      echo "Copying script..."
      cp ./files/get_release.sh ./get_release.sh || { echo "Copy failed with status $?"; ls -la ./files/get_release.sh; exit 1; }
      
      echo "Script contents:"
      cat ./get_release.sh
      
      echo "Making script executable..."
      chmod +x ./get_release.sh || { echo "Chmod failed with status $?"; exit 1; }
      
      echo "Environment:"
      env
      
      echo "Shell version:"
      sh --version || true
      
      echo "Available commands:"
      which curl jq wget tar gzip || true
      
      echo "Running script..."
      sh -x ./get_release.sh ${var.owner} ${var.repo} ${var.release_version} ${var.asset_name} || { echo "Script execution failed with status $?"; exit 1; }
    EOT
    interpreter = ["/bin/sh", "-c"]
  }

  provisioner "local-exec" {
    command = "gsutil -m rsync -r -c -d release_contents/ gs://${var.bucket_name}"
  }

  provisioner "local-exec" {
    command = "rm -rf release_contents"
    when    = destroy
  }
}
