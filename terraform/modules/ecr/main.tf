# ============================================
# ECR Repositories - for_each on services map
# ============================================
resource "aws_ecr_repository" "main" {
  for_each = var.services

  name                 = "${var.project_name}/${each.value.name}"
  image_tag_mutability = "MUTABLE"
  force_delete         = var.environment != "prod"

  image_scanning_configuration {
    scan_on_push = var.environment == "prod"
  }

  encryption_configuration {
    encryption_type = "KMS"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${each.key}-ecr"
  })
}

# ============================================
# Lifecycle Policy - Keep last 10 images
# ============================================
resource "aws_ecr_lifecycle_policy" "main" {
  for_each = var.services

  repository = aws_ecr_repository.main[each.key].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}