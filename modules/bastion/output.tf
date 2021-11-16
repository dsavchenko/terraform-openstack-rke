output "bastion_ip" {
    value = "${openstack_networking_floatingip_v2.floatip.0.address}"
}