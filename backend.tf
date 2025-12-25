terraform {
  backend "s3" {
    bucket         = your-bucket-name               # S3 bucket name
    key            = "env/dev/terraform.tfstate"   # Path inside the bucket
    region         = "your-region"                  # AWS region
    dynamodb_table = "terraform-locks"              # For locking
    encrypt        = true
  }
}
