
# S3 Bucket to store the state file  

#===========================================================
resource "aws_s3_bucket" "qualitlabs" {
  bucket = "krishna-store-statefile-bucket"

  lifecycle {
    prevent_destroy = true
  }


  tags = {
    Name        = "statefile_bucket_on_dev"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.qualitlabs.id

  versioning_configuration {
    status = "Enabled"
  }
}

#=============================================================


#DynamoDB table to lock the state file

#=============================================================
resource "aws_dynamodb_table" "terraform_lock" {
  name = "terraform_lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"

  attribute {
     name = "LockID"
     type = "S"  
  }
}
#=============================================================

terraform {
 backend "s3" {
    bucket         = "krishna-store-statefile-bucket"
    key            = "terraform/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform_lock"
  }
}

