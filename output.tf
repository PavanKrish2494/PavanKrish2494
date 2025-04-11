output "ec2_public_ip" {
  value = aws_instance.jenkins_server.public_ip
}

output "ec2_private_ip" {
  value = aws_instance.jenkins_server.private_ip
}

output "ssh_access_command" {
  value = "ssh -i ~/.ssh/id_rsa ubuntu@${aws_instance.jenkins_server.public_ip}"
}
