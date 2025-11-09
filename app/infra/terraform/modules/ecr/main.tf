resource "aws_ecr_repository" "this" {
  count                = var.create_repository ? 1 : 0
  name                 = var.repository_name
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.encryption_type
  }

  tags = var.tags
}

data "aws_ecr_repository" "existing" {
  count          = var.create_repository ? 0 : 1
  name           = var.repository_name
  registry_id    = null
}

locals {
  repository_name = var.create_repository ? aws_ecr_repository.this[0].name : data.aws_ecr_repository.existing[0].name
  repository_url  = var.create_repository ? aws_ecr_repository.this[0].repository_url : data.aws_ecr_repository.existing[0].repository_url
  repository_arn  = var.create_repository ? aws_ecr_repository.this[0].arn : data.aws_ecr_repository.existing[0].arn
}

resource "aws_ecr_lifecycle_policy" "this" {
  count       = var.create_repository ? 1 : 0
  repository  = local.repository_name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last ${var.image_count} images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["latest"],
          countType     = "imageCountMoreThan",
          countNumber   = var.image_count
        },
        action = { type = "expire" }
      },
      {
        rulePriority = 2,
        description  = "Expire untagged images after ${var.untagged_image_days} days",
        selection = {
          tagStatus   = "untagged",
          countType   = "sinceImagePushed",
          countUnit   = "days",
          countNumber = var.untagged_image_days
        },
        action = { type = "expire" }
      }
    ]
  })
}



