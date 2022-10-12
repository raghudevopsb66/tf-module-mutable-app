resource "aws_instance" "ondemand" {
  count                  = var.INSTANCES["ONDEMAND"].instance_count
  instance_type          = var.INSTANCES["ONDEMAND"].instance_type
  ami                    = data.aws_ami.ami.image_id
  subnet_id              = data.terraform_remote_state.infra.outputs.app_subnets[count.index]
  vpc_security_group_ids = [aws_security_group.main.id]
  iam_instance_profile   = aws_iam_instance_profile.parameter-store-access.name
  lifecycle {
    ignore_changes = [
      # Prevents clobbering the tags of attached EBS volumes
      tags,
      tags_all
    ]
  }
}

resource "aws_spot_instance_request" "spot" {
  count                  = var.INSTANCES["SPOT"].instance_count
  instance_type          = var.INSTANCES["SPOT"].instance_type
  ami                    = data.aws_ami.ami.image_id
  subnet_id              = data.terraform_remote_state.infra.outputs.app_subnets[count.index]
  wait_for_fulfillment   = true
  vpc_security_group_ids = [aws_security_group.main.id]
  iam_instance_profile   = aws_iam_instance_profile.parameter-store-access.name
}


resource "aws_ec2_tag" "name-tag" {
  count       = length(local.ALL_INSTANCE_IDS)
  resource_id = element(local.ALL_INSTANCE_IDS, count.index)
  key         = "Name"
  value       = "${var.COMPONENT}-${var.ENV}"
}

resource "aws_ec2_tag" "prometheus-tag" {
  count       = length(local.ALL_INSTANCE_IDS)
  resource_id = element(local.ALL_INSTANCE_IDS, count.index)
  key         = "Monitor"
  value       = "Yes"
}

resource "null_resource" "ansible-apply" {
  triggers = {
    instances = join(",", local.ALL_INSTANCE_IDS)
    abc       = timestamp()
  }
  count = length(local.ALL_PRIVATE_IPS)
  provisioner "remote-exec" {
    connection {
      host     = element(local.ALL_PRIVATE_IPS, count.index)
      user     = local.ssh_username
      password = local.ssh_password
    }

    inline = [
      "ansible-pull -i localhost, -U https://github.com/raghudevopsb66/roboshop-mutable-ansible roboshop.yml -e HOSTS=localhost -e APP_COMPONENT_ROLE=${var.COMPONENT} -e ENV=${var.ENV}"
    ]
  }
}

resource "aws_security_group" "main" {
  name        = "${var.ENV}-${var.COMPONENT}"
  description = "${var.ENV}-${var.COMPONENT}"
  vpc_id      = data.terraform_remote_state.infra.outputs.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.infra.outputs.vpc_cidr, data.terraform_remote_state.infra.outputs.workstation_ip]
  }

  ingress {
    description = "APP"
    from_port   = var.APP_PORT
    to_port     = var.APP_PORT
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.infra.outputs.vpc_cidr]
  }

  ingress {
    description = "PROMETHEUS"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [var.PROMETHEUS_IP]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.ENV}-${var.COMPONENT}"
  }
}