resource "null_resource" "web_deployer" {
  # Clone down the released version of the web assets
  provisioner "local-exec" {
    command = "./get_release.sh ${var.owner} ${var.repo} ${var.release_version} ${var.asset_name}"
  }

  # Copy the release into the GCS bucket
  provisioner "local-exec" {
    command = "gsutil -m rsync -r -c -d ./${var.asset_dir} gs://${var.bucket_name}"
  }

  # Cleanup step
  provisioner "local-exec" {
    command = "rm -rf ./${var.asset_dir}"
  }
}
