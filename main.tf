variable "region" {
  default = "us-east-1"
}

variable "shared_credentials_file" {
  default = "/Users/latikaw/.aws/credentials"
}

variable "profile" {
  default = "terraform"
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default = 8080
}

provider "aws" {
  region = "${var.region}"
  shared_credentials_file = "${var.shared_credentials_file}"
  profile = "${var.profile}"
  
}

#data "aws_availability_zones" "all" {}

#resource "aws_instance" "example" {
#  ami = "ami-2d39803a"
#  instance_type = "t2.micro"
#  vpc_security_group_ids = ["${aws_security_group.instance.id}"]

#  lifecycle {
#    create_before_destroy = true
#  }
#
#  user_data = <<-EOF
#              #!/bin/bash
#              echo "Hello, World" > index.html
#              nohup busybox httpd -f -p "${var.server_port}" &
#              EOF
#}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"
  ingress {
    from_port = "${var.server_port}"
    to_port = "${var.server_port}"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "example" {
  image_id = "ami-2d39803a"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.instance.id}"]
  user_data = <<-EOF
              #!/bin/bash
              echo "hello world" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = "${aws_launch_configuration.example.id}"
  #availability_zones = ["${data.aws_availability_zones.all.names}"]
  availability_zones = ["us-east-1a", "us-east-1b"]

  min_size = 2
  max_size = 2
 
  load_balancers = ["${aws_elb.example.name}"]
  health_check_type = "ELB"
  
  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_elb" "example" {
  name = "terraform-asg-example"
  security_groups = ["${aws_security_group.elb.id}"]
  #availability_zones = ["${data.aws_availability_zones.all.names}"]
  availability_zones = ["us-east-1a", "us-east-1b"]

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:${var.server_port}/"
  }

  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "${var.server_port}"
    instance_protocol = "http"
  }
}

resource "aws_security_group" "elb" {
  name = "terraform-example-elb"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

##################################################################################
# OUTPUT
##################################################################################

#output "aws_instance_public_dns" {
#    value = "${aws_instance.example.public_dns}"
#}
