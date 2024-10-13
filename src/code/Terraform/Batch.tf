
#Gerado com auxilio de inteligencia artificial#

provider "aws" {
  region = "us-east-1"
}

# S3 Bucket para salvar os arquivos processados
resource "aws_s3_bucket" "processed_files_bucket" {
  bucket = "processed-files-bucket"
  acl    = "private"
}

# Criação do Job Definition para AWS Batch
resource "aws_batch_job_definition" "my_job_definition" {
  name       = "my-job-definition"
  type       = "container"
  container_properties = jsonencode({
    image       = "my-batch-job-image"
    vcpus       = 2
    memory      = 4096
    command     = ["/bin/bash", "-c", "python3 process_files.py"]
  })
}

# AWS Batch Compute Environment
resource "aws_batch_compute_environment" "my_compute_environment" {
  compute_environment_name = "my-compute-environment"
  type                     = "MANAGED"
  compute_resources {
    type                = "EC2"
    instance_role       = aws_iam_instance_profile.batch_instance_profile.arn
    instance_types      = ["m4.large"]
    max_vcpus           = 16
    security_group_ids  = [aws_security_group.batch_sg.id]
    subnets             = [aws_subnet.private.id]
  }
  state = "ENABLED"
}

# AWS Batch Job Queue
resource "aws_batch_job_queue" "my_job_queue" {
  name                 = "my-job-queue"
  state                = "ENABLED"
  priority             = 1
  compute_environments = [aws_batch_compute_environment.my_compute_environment.arn]
}

# IAM Role para AWS Batch
resource "aws_iam_role" "batch_service_role" {
  name = "batch-service-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "batch.amazonaws.com"
      }
    }]
  })
}

# S3 Bucket Policy para acessar os arquivos
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.processed_files_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Principal = "*"
      Action   = "s3:GetObject"
      Resource = "${aws_s3_bucket.processed_files_bucket.arn}/*"
    }]
  })
}
