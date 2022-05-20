################################################################################
# EC2
################################################################################

resource "aws_instance" "sv" {
  ami                         = "ami-0afe0424c9fd49524"
  instance_type               = "t2.nano"
  subnet_id                   = aws_subnet.subnets[keys(aws_subnet.subnets)[0]].id
  vpc_security_group_ids      = [aws_security_group.sv.id]
  ebs_optimized               = false
  monitoring                  = false
  associate_public_ip_address = true

  user_data = <<-EOS
    #cloud-config
    timezone: "Asia/Tokyo"
    write_files:
    - path: /etc/dnsmasq.d/example.conf
      owner: root:root
      permissions: '0644'
      content: |
        host-record =           ${local.env.forward_domain},192.0.2.100
        host-record =       aaa.${local.env.forward_domain},192.0.2.101
        host-record = aaa.alice.${local.env.forward_domain},192.0.2.102
        host-record = rds.alice.${local.env.forward_domain},192.0.2.103
    runcmd:
      - systemctl disable firewalld --now
      - systemctl disable iptables --now
      - dnf -y install bind-utils nmap-ncat
      - dnf -y module install postgresql:13/client
      - dnf -y install dnsmasq
      - systemctl enable dnsmasq --now
  EOS

  tags = {
    Name = "${local.env.tag}-sv"
  }

  root_block_device {
    volume_type = "gp2"
    volume_size = 8

    tags = {
      Name = "${local.env.tag}-sv"
    }
  }

  lifecycle {
    ignore_changes = [
      user_data,
    ]
  }
}

output "instance" {
  value = {
    instance_id = aws_instance.sv.id
    public_ip   = aws_instance.sv.public_ip
    private_ip  = aws_instance.sv.private_ip
  }
}
