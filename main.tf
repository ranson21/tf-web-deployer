resource "terraform_data" "version" {
  input = var.release_version
}

resource "null_resource" "web_deployer" {
  triggers = {
    version = terraform_data.version.output
  }

  provisioner "local-exec" {
    command     = <<-EOT
      pwd
      echo "Files directory contents:"
      ls -la ./files/
      
      echo "Copying script..."
      cp ./files/get_release.sh ./get_release.sh || { echo "Copy failed with status $?"; ls -la ./files/get_release.sh; exit 1; }
      
      echo "Verifying copy:"
      ls -la ./get_release.sh || echo "Script not found after copy"
      
      echo "Making script executable..."
      chmod +x ./get_release.sh || { echo "Chmod failed with status $?"; exit 1; }
      
      echo "Running script with bash..."
      bash -x ./get_release.sh ${var.owner} ${var.repo} ${var.release_version} ${var.asset_name} || { echo "Script execution failed with status $?"; exit 1; }
    EOT
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    command = "gsutil -m rsync -r -c -d release_contents/ gs://${var.bucket_name}"
  }

  provisioner "local-exec" {
    command = "rm -rf release_contents"
    when    = destroy
  }
}
