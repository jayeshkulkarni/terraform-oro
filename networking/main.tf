#----networking/main.tf

data "aws_availability_zones" "available" {}

#resource "aws_vpc" "tf_vpc" {
#  cidr_block           = "${var.vpc_cidr}"
#  enable_dns_hostnames = true
#  enable_dns_support   = true
#
#  tags {
#    Name = "tf_vpc" 
#  }
#}


data "aws_vpc" "custom" {
id = "${var.vpc_id}"
}

#resource "aws_internet_gateway" "tf_internet_gateway" {
#  vpc_id = "${data.aws_vpc.custom.id}"
#
#  tags {
#    Name = "tf_igw"
#  }
#}

data "aws_internet_gateway" "default" {
filter {
name = "attachment.vpc-id"
values = ["${data.aws_vpc.custom.id}"]
}
}


resource "aws_route_table" "tf_public_rt" {
  vpc_id = "${data.aws_vpc.custom.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${data.aws_internet_gateway.default.id}"
  }
 
  tags {
    Name = "tf_public"
  }
}

resource "aws_default_route_table" "tf_private_rt" {
  default_route_table_id = "${data.aws_vpc.custom.id.default_route_table_id}"

  tags {
    Name = "tf_private"
  }
}

resource "aws_subnet" "tf_public_subnet" {
  count                   = 2
  vpc_id                  = "${data.aws_vpc.custom.id}"
  cidr_block              = "${var.public_cidrs[count.index]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"

  tags {
    Name = "tf_public_${count.index + 1}"
  }
}

resource "aws_route_table_association" "tf_public_assoc" {
  count          = "${aws_subnet.tf_public_subnet.count}"
  subnet_id      = "${aws_subnet.tf_public_subnet.*.id[count.index]}"
  route_table_id = "${aws_route_table.tf_public_rt.id}"
}

resource "aws_security_group" "tf_public_sg" {
  name        = "tf_public_sg"
  description = "Used for access to the public instances"
  vpc_id      = "${data.aws_vpc.custom.id}"

  #SSH

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.accessip}"]
  }

  #HTTP

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.accessip}"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#create an elastic load balancer
resource "aws_elb" "prod-b-elb" {
  name = "oro-elb"
  security_groups = ["${aws_security_group.tf_public_sg.id}"]
  subnets = ["${aws_subnet.tf_public_subnet.id}"]

  #bucket to store access logs
  #access_logs {
  #  bucket = "oro-logs"
  #  bucket_prefix = "oro-elb-access"
  #  interval = 60
  #}

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  listener {
    instance_port = 443
    instance_protocol = "tcp"
    lb_port = 443
    lb_protocol = "tcp"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:80/"
    interval = 30
  }

  #register web-* instances to ELB resource
  #instances = ["${aws_instance.web.*.id}"]
  #cross_zone_load_balancing = true
  #idle_timeout = 400
  #connection_draining = true
  #connection_draining_timeout = 400

  tags {
    Name = "oro-prod-elb"
  }
}