
resource "aws_key_pair" "ssh_pub" {
  key_name   = "${var.owner}-ssh-key"
  public_key = var.ssh_key == "" ? file("~/.ssh/id_rsa.pub") : var.ssh_key
}

############### Storage Location Base #################
resource "aws_s3_bucket" "cdp" {
  bucket = "${var.owner}-cdp-bucket"

  tags = {
    Name        = "${var.owner}-cdp-bucket"
    owner       = var.owner
  }
}

resource "aws_s3_object" "folders" {
  for_each = toset(["data", "logs", "backups", "ranger"])
  bucket = aws_s3_bucket.cdp.id
  key    = "${each.value}/"
  source = "/dev/null"
}

output "storage_locations" {
  value = [for x in aws_s3_object.folders : "${aws_s3_bucket.cdp.id}/${x.key}" ]
}