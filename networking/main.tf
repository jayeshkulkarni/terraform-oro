#----networking/main.tf

provider "aws" {
access_key = "${var.aws_access_key}"
secret_key = "${var.aws_secret_key}"
region = "${var.aws_region}"
}


data "aws_vpc" "custom" {
id = "${var.vpc_id}"
}

data "aws_availability_zones" "available" {}

data "aws_internet_gateway" "default" {
filter {
name = "attachment.vpc-id"
values = ["${data.aws_vpc.custom.id}"]
}
}

resource "aws_eip" "nat" {
vpc = true
}

resource "aws_route_table" "public_rt" {
vpc_id = "${data.aws_vpc.custom.id}"

route {
cidr_block = "0.0.0.0/0"
gateway_id = "${data.aws_internet_gateway.default.id}"
}

tags {
Name = "Jayesh-Public-rt"
}
}

resource "aws_default_route_table" "private_rt" {
default_route_table_id = "${data.aws_vpc.custom.id.default_route_table_id}"

tags {
Name = "Jayesh-Default-rt"
}
}

resource "aws_subnet" "public" {
count = 2
vpc_id = "${data.aws_vpc.custom.id}"
cidr_block = "${var.public_cidr[count.index]}"
availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
map_public_ip_on_launch = true
tags {
Name = "Jayesh_public_${count.index + 1}"
}

}

resource "aws_route_table_association" "route_tabl_asso" {
count = "${aws_subnet.public.count}"
subnet_id = "${aws_subnet.public.*.id[count.index]}"
route_table_id = "${aws_route_table.public_rt.id}"
}

resource "aws_nat_gateway" "nat" {
#count = "${aws_subnet.public.count}"
allocation_id = "${aws_eip.nat.id}"
subnet_id = "${aws_subnet.public.*.id[0]}"
tags {
Name = "NAT GW"
}
depends_on = ["data.aws_internet_gateway.default"]
}

resource "aws_route_table" "private_rt" {
vpc_id = "${data.aws_vpc.custom.id}"

route {
cidr_block = "0.0.0.0/0"
nat_gateway_id = "${aws_nat_gateway.nat.id}"
}

tags {
Name = "Jayesh-Private-rt"
}
}


resource "aws_subnet" "private" {
count = 2
vpc_id = "${data.aws_vpc.custom.id}"
cidr_block = "${var.private_cidr[count.index]}"
availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
#map_public_ip_on_launch = true
tags {
Name = "Jayesh_private_${count.index + 1}"
}

}

resource "aws_route_table_association" "route_tabl_asso_pri" {
count = "${aws_subnet.private.count}"
subnet_id = "${aws_subnet.private.*.id[count.index]}"
route_table_id = "${aws_route_table.private_rt.id}"
}

resource "aws_security_group" "proxySG" {
    name = "proxySG"
    description = "HTTP/HTTPS from anywhere"
    vpc_id = "${data.aws_vpc.custom.id}"

    ingress {
        from_port = "80"
        to_port = "80"
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
    }

    ingress {
        from_port = "443"
        to_port = "443"
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
  tags {
    Name = "TF-ProxySG"
  }
}
resource "aws_alb" "proxyalb" {
  name               = "TF-ProxyALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.proxySG.id}"]
  subnets            = ["${aws_subnet.public.*.id}"]

  enable_deletion_protection = true

  #access_logs {
  #  bucket  = "${aws_s3_bucket.lb_logs.bucket}"
  #  prefix  = "test-lb"
  #  enabled = true
  #}

  tags {
    Name = "TF-ProxyALB"
  }
}

resource "aws_alb_target_group" "proxyalb_target_group" {
  name     = "ProxyALB-TG"
  port     = "80"
  protocol = "HTTP"
  vpc_id   = "${data.aws_vpc.custom.id}"
  tags {
    name = "ProxyALB-TG"
  }
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 1800
    enabled         = "${var.proxyalb_sticky}"
  }
  #health_check {
  #  healthy_threshold   = 3
  #  unhealthy_threshold = 10
  #  timeout             = 5
  #  interval            = 10
  #  path                = "${var.target_group_path}"
  #  port                = "${var.target_group_port}"
  #}
}

resource "aws_alb_listener" "proxyalb_listener" {  
  load_balancer_arn = "${aws_alb.proxyalb.arn}"  
  port              = "${var.proxyalb_listener_port}"  
  protocol          = "${var.proxyalb_listener_protocol}"
  
  default_action {    
    target_group_arn = "${aws_alb_target_group.proxyalb_target_group.arn}"
    type             = "forward"  
  }
}
resource "aws_alb_listener_rule" "proxyalb_listener_rule" {
  depends_on   = ["aws_alb_target_group.proxyalb_target_group"]  
  listener_arn = "${aws_alb_listener.proxyalb_listener.arn}"  
  priority     = 100   
  action {    
    type             = "forward"    
    target_group_arn = "${aws_alb_target_group.proxyalb_target_group.arn}"  
  }   
  condition {    
    field  = "path-pattern"    
    values = ["/static/*"]  
  }
}

#Autoscaling Attachment
#resource "aws_autoscaling_attachment" "svc_asg_external2" {
#  alb_target_group_arn   = "${aws_alb_target_group.alb_target_group.arn}"
#  autoscaling_group_name = "${aws_autoscaling_group.svc_asg.id}"
#}
#Instance Attachment
#resource "aws_alb_target_group_attachment" "svc_physical_external" {
#  target_group_arn = "${aws_alb_target_group.alb_target_group.arn}"
#  target_id        = "${aws_instance.svc.id}"  
#  port             = 8080
#}
