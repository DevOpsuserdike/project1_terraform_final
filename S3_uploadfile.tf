resource "aws_s3_bucket" "uploadCSVfilebucket" {
  bucket = "uploadcsvfilebucket20260222" # Must be globally unique

  tags = {
    Name        = "uploadCSVfilebucket_terraform"
    
  }
}

output "uploadCSVfilebucketarn" {
  value = aws_s3_bucket.uploadCSVfilebucket.arn
}