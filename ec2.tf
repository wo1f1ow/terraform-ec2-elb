# random name generator
resource "random_pet" "ec2" {}

resource "aws_instance" "private" {
  ami           = data.aws_ami.amazon-linux-2.id
  instance_type = "t2.small"
  availability_zone = element(var.availability_zones,0)
  subnet_id     = aws_subnet.private.id
  iam_instance_profile  = aws_iam_instance_profile.systems_manager.name
  vpc_security_group_ids = ["${aws_security_group.offsec.id}"]
  root_block_device {
    encrypted = "true"
  }

  tags = {
    Name = "offsec-${random_pet.ec2.id}"
  }

  user_data = <<EOF
  #!/bin/bash
  echo "Installing docker and git..."
  sudo yum install docker -y
  sudo yum install git -y
  EOF
}

# get the most recent amazon image
data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name    = "name"
    values  = ["amzn2-ami-kernel*"]
  }
  filter {
    name    = "virtualization-type"
    values  = ["hvm"]
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance" {
  name               = "instance_ssm_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy" "systems_manager" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.instance.name
  policy_arn = data.aws_iam_policy.systems_manager.arn
}

# Define instance policy
resource "aws_iam_instance_profile" "systems_manager" {
  name = "ssm_instance_profile"
  role = aws_iam_role.instance.name
}

resource "aws_ebs_volume" "instance" {
  availability_zone = element(var.availability_zones,0)
  size              = 8
  encrypted         = "true"
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.instance.id
  instance_id = aws_instance.private.id
}
