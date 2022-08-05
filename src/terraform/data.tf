data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "template_file" "cloud-init" {
  template = file("${path.module}/cloud-init.sh")
}

data "template_cloudinit_config" "user_data" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "cloud-init.sh"
    content_type = "text/x-shellscript"
    content      = data.template_file.cloud-init.rendered
  }
}
