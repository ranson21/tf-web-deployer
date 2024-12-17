resource "terraform_data" "version" {
  input = var.release_version
}

resource "null_resource" "web_deployer" {
  triggers = {
    version = terraform_data.version.output
  }

  provisioner "local-exec" {
    command = <<-EOT
      pwd
      ls -la
      echo "Creating release_contents directory..."
      mkdir -p release_contents
      
      echo "Current directory contents:"
      ls -la
      
      echo "Files directory contents:"
      ls -la ./files || echo "Files directory not found"
      
      echo "Module path contents:"
      ls -la ${path.module}
      
      echo "Copying script..."
      cp ${path.module}/files/get_release.sh ./get_release.sh || echo "Copy failed"
      
      echo "Making script executable..."
      chmod +x ./get_release.sh || echo "Chmod failed"
      
      echo "Running script..."
      ./get_release.sh ${var.owner} ${var.repo} ${var.release_version} ${var.asset_name}
    EOT
  }

  provisioner "local-exec" {
    command = "gsutil -m rsync -r -c -d release_contents/ gs://${var.bucket_name}"
  }

  provisioner "local-exec" {
    command = "rm -rf release_contents"
    when    = destroy
  }
}
