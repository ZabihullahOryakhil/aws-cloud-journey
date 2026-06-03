output "web_url" {
  value = module.compute.web_url
}
output "instance_id" {
  value = module.compute.instance_id
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "bucket" {
  value = module.storage.bucket_name
}