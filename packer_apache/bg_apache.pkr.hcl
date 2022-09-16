packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "ami_prefix" {
  type    = string
  default = "ami-apache"
}
variable "color_green" {
  type    = string
  default = "green"
}
variable "color_blue" {
  type    = string
  default = "blue"
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}


source "amazon-ebs" "apache-green" {
  ami_name      = "${var.ami_prefix}-${var.color_green}"
  instance_type = "t3.small"
  region        = "ap-south-1"
  // vpc_id                      = "vpc-0f20e8ddf56dc2520"
  // subnet_id                   = "subnet-08cabd7e59e80aa23"
  // security_group_id           = "sg-0b2ff4d33f1c10f4a"
  vpc_filter {
    filters = {
      "tag:Name" : "bg-vpc"
      isDefault = "false"
      cidr      = "172.168.0.0/16"
    }
  }
  subnet_filter {
    filters = {
      "tag:Name" : "public-subnet-1"
    }
    most_free = true
    random    = false
  }
  associate_public_ip_address = true
  force_deregister            = true
  force_delete_snapshot       = true
  deprecate_at                = timeadd(timestamp(), "8760h")

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  tags = {
    Name = "ami-apache-green"
  }
  ssh_username = "ubuntu"
}

build {
  name = "packer-Green"
  sources = [
    "source.amazon-ebs.apache-green"
  ]
  provisioner "ansible" {
    playbook_file   = "./playbooks/main_apache.yml"
    extra_arguments = ["--extra-vars", "bg_color=${var.color_green}"]
  }

}

source "amazon-ebs" "apache-blue" {
  ami_name      = "${var.ami_prefix}-${var.color_blue}"
  instance_type = "t3.small"
  region        = "ap-south-1"
  // vpc_id                      = "vpc-0f20e8ddf56dc2520"
  // subnet_id                   = "subnet-08cabd7e59e80aa23"
  // security_group_id           = "sg-0b2ff4d33f1c10f4a"
  vpc_filter {
    filters = {
      "tag:Name" : "bg-vpc"
      isDefault = "false"
      cidr      = "172.168.0.0/16"
    }
  }
  subnet_filter {
    filters = {
      "tag:Name" : "public-subnet-1"
    }
    most_free = true
    random    = false
  }
  associate_public_ip_address = true
  force_deregister            = true
  force_delete_snapshot       = true
  deprecate_at                = timeadd(timestamp(), "8760h")

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  tags = {
    Name = "ami-apache-blue"
  }

  ssh_username = "ubuntu"
}

build {
  name = "packer-Blue"
  sources = [
    "source.amazon-ebs.apache-blue"
  ]
  provisioner "ansible" {
    playbook_file   = "./playbooks/main_apache.yml"
    extra_arguments = ["--extra-vars", "bg_color=${var.color_blue}"]
  }

}