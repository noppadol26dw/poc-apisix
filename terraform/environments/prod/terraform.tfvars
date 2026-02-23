aws_region           = "ap-southeast-1"
project_name         = "apisix"
environment          = "prod"
vpc_cidr             = "10.128.0.0/16"
public_subnet_cidrs  = ["10.128.1.0/24", "10.128.2.0/24", "10.128.3.0/24"]
private_subnet_cidrs = ["10.128.10.0/24", "10.128.11.0/24", "10.128.12.0/24"]
cluster_name         = "apisix-cluster"
cluster_version      = "1.34"
node_instance_types  = ["t3.large"]
node_desired_size    = 2
node_max_size        = 5
node_min_size        = 3
# No custom domain; CloudFront will use default URL (xxx.cloudfront.net). Set when you have a domain.
domain_name = ""
