#S3 bucket
resource "aws_s3_bucket" "terraform_state" {
provider = aws.us-east-1
bucket = "myproject-tfstate"
#prevent accidental deletion
lifecycle{
    prevent_destroy = true
    }  
}
#Enable bucket versioning for fallback mechanisms on state files
resource "aws_s3_bucket_versioning" "enabled" {
bucket = aws_s3_bucket.terraform_state.id
versioning_configuration {
    status = "Enabled"
    }
}
#Enable server-side encryption for bucket by default
resource "aws_s3_bucket_server_side_encryption_configuration" "default_encryption" {
bucket = aws_s3_bucket.terraform_state.id
rule {
    apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
        }
    }
}
#Explicitly block all public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "public_access_block" {
bucket = aws_s3_bucket.terraform_state.id
block_public_acls = true
block_public_policy = true
ignore_public_acls = true
restrict_public_buckets = true
}
#DynamoDB table for locking state file
#DynamoDB allows to create DynamoDB table with primary key, LockID
resource "aws_dynamodb_table" "terraform_locks" {
name = "terraform-locks"
billing_mode = "PAY_PER_REQUEST"
hash_key = "LockID"
attribute {
    name = "LockID"
    type = "S"
    }
}
#Backend to store state files in S3 bucket
terraform {
backend "s3" {
    bucket = "myproject-tfstate"
    key = "s3/prod/terraform.tfstate" #file path to store state file
    dynamodb_table = "terraform-lock"
    region = "us-east-1"
    encrypt = true
    }
}