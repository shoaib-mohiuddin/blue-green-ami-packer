packer {
  required_plugins {
    amazon = {
      version = ">= 1.1.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "blue_ami_name" {
  type    = string
  default = "ami-nginx-blue"
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "Blue-web-server" {
  ami_name              = "${var.blue_ami_name}"
  instance_type         = "t2.micro"
  region                = "ap-south-1"
  force_deregister      = true
  force_delete_snapshot = true
  deprecate_at          = timeadd(timestamp(), "8760h")

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
    Name = "ami-nginx-blue"
  }
  ssh_username = "ubuntu"
}

variable "green_ami_name" {
  type    = string
  default = "ami-nginx-green"
}

source "amazon-ebs" "Green-web-server" {
  ami_name              = "${var.green_ami_name}"
  instance_type         = "t2.micro"
  region                = "ap-south-1"
  force_deregister      = true
  force_delete_snapshot = true
  deprecate_at          = timeadd(timestamp(), "8760h")

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

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-focal-20.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  tags = {
    Name = "ami-nginx-green"
  }
  ssh_username = "ubuntu"
}

build {
  name = "blue-build"
  sources = [
    "source.amazon-ebs.Blue-web-server"
  ]

  provisioner "ansible" {
    playbook_file   = "./playbooks/main_nginx.yml"
    extra_arguments = ["--extra-vars", "@./packer_nginx/c_blue.yml"]

  }
}

build {
  name = "green-build"
  sources = [
    "source.amazon-ebs.Green-web-server"
  ]

  provisioner "ansible" {
    playbook_file   = "./playbooks/main_nginx.yml"
    extra_arguments = ["--extra-vars", "@./packer_nginx/c_green.yml"]

  }
}