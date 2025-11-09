# ===========================================
# ECS Module - Fargate Only
# ===========================================
module "ecs" {
  source = "./modules/ecs"

  # Common
  aws_region   = var.aws_region
  lab_role_arn = var.lab_role_arn

  # Cluster Configuration
  cluster_name              = var.ecs_cluster_name
  enable_container_insights = var.ecs_enable_container_insights

  # Task Definition Configuration
  task_family           = var.ecs_task_family
  container_name        = var.ecs_container_name
  container_image       = var.ecs_container_image
  container_cpu         = var.ecs_container_cpu
  container_memory      = var.ecs_container_memory
  container_port        = var.ecs_container_port
  container_environment = var.ecs_container_environment

  # Service Configuration
  service_name  = var.ecs_service_name
  desired_count = var.ecs_desired_count

  # Networking Configuration
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.private_subnet_ids
  security_group_ids    = [module.vpc.ecs_container_security_group_id]
  ecs_security_group_id = module.vpc.ecs_container_security_group_id

  # IAM Roles
  execution_role_arn = var.ecs_execution_role_arn != "" ? var.ecs_execution_role_arn : var.lab_role_arn
  task_role_arn      = var.ecs_task_role_arn != "" ? var.ecs_task_role_arn : var.lab_role_arn

  # Load Balancer Configuration - ALWAYS ENABLED
  create_alb                     = true
  alb_name                       = var.ecs_alb_name
  alb_subnet_ids                 = module.vpc.public_subnet_ids
  alb_idle_timeout               = var.ecs_alb_idle_timeout
  alb_enable_deletion_protection = var.ecs_alb_enable_deletion_protection
  alb_certificate_arn            = var.ecs_alb_certificate_arn
  alb_ssl_policy                 = var.ecs_alb_ssl_policy

  # Health Check Configuration
  health_check_enabled             = var.ecs_health_check_enabled
  health_check_interval            = var.ecs_health_check_interval
  health_check_path                = var.ecs_health_check_path
  health_check_timeout             = var.ecs_health_check_timeout
  health_check_healthy_threshold   = var.ecs_health_check_healthy_threshold
  health_check_unhealthy_threshold = var.ecs_health_check_unhealthy_threshold
  health_check_matcher             = var.ecs_health_check_matcher

  # Logging
  log_retention_days = var.ecs_log_retention_days

  tags = var.tags
}

