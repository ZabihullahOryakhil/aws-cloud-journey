module "network" {
  source = "../modules/network"
  environment = var.environment
  region = var.region
}

module "storage" {
  source = "../modules/storage"
  environment = var.environment
  bucket_name = var.bucket_name
}

module "compute" {
  source = "../modules/compute"
  environment = var.environment
  instance_type = var.instance_type
  vpc_id = module.network.vpc_id
  subnet_id = module.network.subnet_id
  bucket_arn = module.storage.bucket_arn
}
