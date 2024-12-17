resource "terraform_data" "version" {
  input = var.release_version
}

resource "null_resource" "web_deployer" {
  triggers = {
    version = terraform_data.version.output
  }

  provisioner "local-exec" {
    command = <<-EOT
      mkdir -p release_contents
      cp ${path.module}/files/get_release.sh "${path.module}/get_release.sh"
      chmod +x "${path.module}/get_release.sh"
      cd release_contents
      "${path.module}/get_release.sh" ${var.owner} ${var.repo} ${var.release_version} ${var.asset_name}
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
