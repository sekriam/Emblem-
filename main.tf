#Creates AWS S3 Bucket 
resource "aws_s3_bucket" "bucket" {
  bucket = "emblem_bucket"

  tags = {
    Name        = "emblem_bucket"
    Environment = "Dev"
  }
}



