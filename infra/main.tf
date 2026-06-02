terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

data "aws_default_vpc" "default" {}

data "aws_default_subnet_ids" "default" {
  vpc_id = data.aws_default_vpc.default.id
}

resource "aws_security_group" "db" {
  name        = "${var.namespace}-db-sg"
  description = "Security group for InsightHub Postgres"
  vpc_id      = data.aws_default_vpc.default.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_default_vpc.default.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.namespace}-db-sg"
  }
}

resource "aws_security_group" "redis" {
  name        = "${var.namespace}-redis-sg"
  description = "Security group for InsightHub Redis"
  vpc_id      = data.aws_default_vpc.default.id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [data.aws_default_vpc.default.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.namespace}-redis-sg"
  }
}

resource "aws_db_subnet_group" "insighthub" {
  name       = "${var.namespace}-db-subnet-group"
  subnet_ids = data.aws_default_subnet_ids.default.ids

  tags = {
    Name = "${var.namespace}-db-subnet-group"
  }
}

resource "aws_db_parameter_group" "insighthub" {
  name        = "${var.namespace}-postgres-pg"
  family      = "postgres16"
  description = "Postgres parameter group for InsightHub"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  tags = {
    Name = "${var.namespace}-postgres-pg"
  }
}

resource "aws_db_instance" "insighthub" {
  identifier                 = "${var.namespace}-db"
  engine                     = "postgres"
  engine_version             = "16"
  instance_class             = "db.t4g.micro"
  allocated_storage          = 20
  storage_encrypted          = true
  publicly_accessible        = false
  db_subnet_group_name       = aws_db_subnet_group.insighthub.name
  vpc_security_group_ids     = [aws_security_group.db.id]
  username                   = var.postgres_username
  password                   = var.postgres_password
  skip_final_snapshot        = true
  backup_retention_period    = 7
  auto_minor_version_upgrade = true
  parameter_group_name       = aws_db_parameter_group.insighthub.name

  tags = {
    Name = "${var.namespace}-postgres"
  }
}

resource "aws_elasticache_subnet_group" "insighthub" {
  name       = "${var.namespace}-redis-subnet-group"
  subnet_ids = data.aws_default_subnet_ids.default.ids

  tags = {
    Name = "${var.namespace}-redis-subnet-group"
  }
}

resource "aws_elasticache_cluster" "insighthub" {
  cluster_id                 = "${var.namespace}-redis"
  engine                     = "redis"
  engine_version             = "7.0"
  node_type                  = "cache.t4g.micro"
  num_cache_nodes            = 1
  subnet_group_name          = aws_elasticache_subnet_group.insighthub.name
  security_group_ids         = [aws_security_group.redis.id]
  port                       = 6379
  transit_encryption_enabled = true
  at_rest_encryption_enabled = true

  tags = {
    Name = "${var.namespace}-redis"
  }
}

resource "kubernetes_namespace" "insighthub" {
  metadata {
    name = var.namespace
    labels = {
      app = "insighthub"
    }
  }
}
