aws_region = "ap-south-1"
project_name = "ORO-Wealth"
vpc_id = "vpc-c7bdbba3"
aws_access_key = "xxx"
aws_scret_key = "xxx"
aws_region = "eu-west-1"
public_cidr = [
"172.31.100.0/28", 
"172.31.150.0/28"
]
private_cidr = [
"172.31.200.0/28",
"172.31.250.0/28"
]
proxyalb_listener_protocol = "HTTP"
proxyalb_listener_port = "80"
proxyalb_sticky="true"
key_name = "tf_key" 
public_key_path = "/home/ec2-user/.ssh/id_rsa.pub"
server_instance_type = "t2.micro" 
instance_count = 2