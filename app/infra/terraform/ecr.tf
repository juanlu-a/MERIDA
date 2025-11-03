# ===========================================
# ECR Repository Module - Backend Image
# ===========================================
module "ecr_backend" {
  source = "./modules/ecr"

  repository_name      = var.ecr_repository_name
  image_tag_mutability = var.ecr_image_tag_mutability
  scan_on_push         = var.ecr_scan_on_push
  encryption_type      = var.ecr_encryption_type
  image_count          = var.ecr_image_count
  untagged_image_days  = var.ecr_untagged_image_days

  tags = var.tags
}

