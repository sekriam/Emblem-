# Creating an AWS instance for the Webserver
resource "aws_instance" "webserver" {

  depends_on = [
    aws_vpc.emblem_vpc,
    aws_subnet.subnet1,
    aws_subnet.subnet2
  ]
  
  # AMI ID [I have used my custom AMI which has some softwares pre installed]
  ami = "ami-0866a415f717fa7be"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subnet1.id

  # Keyname and security group are obtained from the reference of their instances created above
  # Here I am providing the name of the key which is already uploaded on the AWS console.
  key_name = "MyKeyFinal"
  
  # Security groups to use
  vpc_security_group_ids = [aws_security_group.WS-SG.id]

  tags = {
   Name = "Webserver_From_Terraform"
  }


  # Code for installing the softwares
  provisioner "remote-exec" {
    inline = [
        "sudo yum update -y",
        "sudo yum install php php-mysqlnd httpd -y",
        "wget https://wordpress.org/wordpress-4.8.14.tar.gz",
        "tar -xzf wordpress-4.8.14.tar.gz",
        "sudo cp -r wordpress /var/www/html/",
        "sudo chown -R apache.apache /var/www/html/",
        "sudo systemctl start httpd",
        "sudo systemctl enable httpd",
        "sudo systemctl restart httpd"
    ]
  }
}