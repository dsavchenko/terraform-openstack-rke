output "bastion_ip" {
    value = "${openstack_networking_floatingip_v2.floatip.0.address}"
}

output "bastion_internal_ip" {
    value = "${openstack_compute_instance_v2.bastion.0.network.0.fixed_ip_v4}"
}