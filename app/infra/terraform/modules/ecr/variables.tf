variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "create_repository" {
  description = "Whether to create the ECR repository. Set to false when repository already exists."
  type        = bool
  default     = true
}

variable "image_tag_mutability" {
  description = "ECR tag mutability (MUTABLE/IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "Scan images on push"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "ECR encryption type (AES256/KMS)"
  type        = string
  default     = "AES256"
}

variable "image_count" {
  description = "Number of tagged images to keep"
  type        = number
  default     = 10
}

variable "untagged_image_days" {
  description = "Days to keep untagged images"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags for ECR"
  type        = map(string)
  default     = {}
}



