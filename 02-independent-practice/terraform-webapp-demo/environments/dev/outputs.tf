output "app_url" {
  value       = "http://${module.compute.alb_dns_name}"
}

output "vpc_id" {
  value = module.networking.vpc_id
}

output "bucket_name" {
  value = module.storage.bucket_name
}