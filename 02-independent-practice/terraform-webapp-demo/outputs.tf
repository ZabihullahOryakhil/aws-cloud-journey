output "app_url" {
  value       = "http://${module.compute.alb_dns_name}"
}

output "alb_dns_name" {
  value       = module.compute.alb_dns_name
}


output "vpc_id" {
  value = module.networking.vpc_id
}

output "public_subnet_ids" {
  value = module.networking.public_subnet_ids
}

output "bucket_name" {
  value       = module.storage.bucket_name
}

output "bucket_arn" {
  value = module.storage.bucket_arn
}


