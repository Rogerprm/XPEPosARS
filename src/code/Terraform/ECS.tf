
####### Gerado com auxilio de inteligencia artificial ########

provider "aws" {
  region = "us-east-1"
}

# S3 Bucket para armazenamento de front-end
resource "aws_s3_bucket" "frontend_bucket" {
  bucket = "frontend-app-bucket"
  acl    = "public-read"
}

# Cloudfront para CDN
resource "aws_cloudfront_distribution" "cdn_distribution" {
  origin {
    domain_name = aws_s3_bucket.frontend_bucket.bucket_domain_name
    origin_id   = "S3-Origin"
  }

  enabled             = true
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Origin"
    viewer_protocol_policy = "redirect-to-https"
  }
}

# API Gateway para gerenciamento de APIs
resource "aws_api_gateway_rest_api" "my_api" {
  name        = "my-api"
  description = "API Gateway for Microservices"
}

# ALB para rotear tráfego para ECS
resource "aws_lb" "alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public.id]
}

# ECS Cluster
resource "aws_ecs_cluster" "my_cluster" {
  name = "my-cluster"
}

# Task Definitions para os Microserviços
resource "aws_ecs_task_definition" "auth_api_task" {
  family                = "auth-api"
  network_mode          = "awsvpc"
  container_definitions = jsonencode([
    {
      name      = "auth-container"
      image     = "my-auth-api-image"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [{
        containerPort = 80
        hostPort      = 80
      }]
    }
  ])
}

# Serviço ECS para Auth API
resource "aws_ecs_service" "auth_api_service" {
  name            = "auth-api-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.auth_api_task.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = [aws_subnet.public.id]
    security_groups  = [aws_security_group.ecs_sg.id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.auth_api_tg.arn
    container_name   = "auth-container"
    container_port   = 80
  }
}

# Cognito para autenticação
resource "aws_cognito_user_pool" "user_pool" {
  name = "user-pool"
}

resource "aws_cognito_user_pool_client" "user_pool_client" {
  name         = "user-pool-client"
  user_pool_id = aws_cognito_user_pool.user_pool.id
}

# RDS para armazenamento de dados
resource "aws_db_instance" "my_rds" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t3.large"
  name                 = "FICTDB"
  username             = "admin"
  password             = "******"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
}
