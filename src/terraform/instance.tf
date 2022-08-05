resource "aws_instance" "this" {
    ami                         = data.aws_ami.ubuntu.id
    instance_type               = "t3.micro"
    associate_public_ip_address = true
    user_data_base64            = data.template_cloudinit_config.user_data.rendered
    key_name                    = aws_key_pair.this.key_name
    vpc_security_group_ids      = [aws_security_group.this.id]
    source_dest_check           = false
    subnet_id                   = aws_subnet.this.id
    user_data_replace_on_change = true
}
