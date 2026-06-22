# Networking Module
module "etworking" {
    source = "value"

    project = var.project
    environment = var.environment
    vpc_cidr = var.vpc_cidr
    public_subnet_cidrs = var.public_subnet_cidrs
    availability_zones = var.availability_zones
}

# Compute module
module "compute" {
  source = "value"
  
  project        = var.project
  environment    = var.environment
  instance_type  = var.instance_type
  instance_count = var.instance_count
  key_name       = var.key_name

  vpc_id            = module.networking.vpc_id
  subnet_ids        = module.networking.public_subnet_ids
  alb_sg_id         = module.networking.alb_sg_id
  ec2_sg_id         = module.networking.ec2_sg_id
}

# Storage module
module "storage" {
  source = "value"
  
  project = var.project
  environment = var.environment
  force_destroy = local.is_prod ? false : true
}