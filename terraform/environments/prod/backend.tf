# terraform {
#   backend "s3" {
#     bucket         = "apisix-terraform-state"
#     key            = "prod/terraform.tfstate"
#     region         = "ap-southeast-1"
#     encrypt        = true
#     dynamodb_table = "apisix-terraform-locks"
#   }
# }
