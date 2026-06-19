locals {
  name_prefix = "${var.project}-${var.environment}"
  is_prod = var.environment == "prod"
}

