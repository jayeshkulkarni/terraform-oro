aws_region = "ap-south-1"
project_name = "ORO-Wealth"
vpc_id = "vpc-30b82559"
public_cidrs = [
    "10.0.100.0/28",
    "10.0.200.0/28"
    ]
accessip = "0.0.0.0/0"
key_name = "tf_key" 
public_key_path = "/home/ec2-user/.ssh/id_rsa.pub"
server_instance_type = "t2.micro" 
instance_count = 2