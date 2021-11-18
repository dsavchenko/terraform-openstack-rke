resource "openstack_compute_instance_v2" "bastion" {
  name            = "mmoda-bastion-nfs"
  count           = var.to_create ? 1 : 0
  image_id        = var.image_id
  flavor_name     = var.flavor
  key_pair        = var.access_key_name
  security_groups = ["default", "nfs"]

  network {
    name = var.network_name
  }

  #TODO: cloud config is not fully portable

  user_data = <<-EOF
  #cloud-config
  package_update: true
  package_upgrade: true
  packages:
  - nfs-kernel-server
  package_reboot_if_required: true
  write_files:
  - content: |
      /export 192.168.42.0/24(rw,sync,no_subtree_check)
    owner: root:root
    path: /etc/exports
    permissions: '0644'
  - content: |
      #!/bin/bash
      while [ ! -b /dev/vdb ] ; do sleep 5; done
      [[ `lsblk /dev/vdb -no FSTYPE` == "" ]] && mkfs.ext4 /dev/vdb
      mkdir -p /export
      mount /dev/vdb /export
      chmod o+w /export
    owner: root:root
    path: /root/mkstorage.sh
    permissions: '0755'
  runcmd:
   - [ bash, /root/mkstorage.sh ]
   - [ systemctl, daemon-reload ]
   - [ systemctl, enable, nfs-kernel-server ]
   - [ systemctl, start, --no-block, nfs-kernel-server ]
   - [ exportfs, -avr ]
  EOF
}

resource "openstack_networking_floatingip_v2" "floatip" {
  count = var.to_create ? 1 : 0
  pool = var.floating_ip_pool
}

resource "openstack_compute_floatingip_associate_v2" "floatip" {
  count = var.to_create ? 1 : 0
  floating_ip = "${openstack_networking_floatingip_v2.floatip.0.address}"
  instance_id = "${openstack_compute_instance_v2.bastion.0.id}"
  fixed_ip    = "${openstack_compute_instance_v2.bastion.0.network.0.fixed_ip_v4}"
}

resource "openstack_blockstorage_volume_v2" "nfsvol" {
  count = var.to_create ? 1 : 0
  name = "mmoda-nfs"
  size = var.volume_size
}

resource "openstack_compute_volume_attach_v2" "attached" {
  count = var.to_create ? 1 : 0
  instance_id = "${openstack_compute_instance_v2.bastion.0.id}"
  volume_id   = "${openstack_blockstorage_volume_v2.nfsvol.0.id}"
}

resource "openstack_networking_secgroup_v2" "nfs" {
  name        = "nfs"
}

resource "openstack_networking_secgroup_rule_v2" "nfs_rule_1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 2049
  port_range_max    = 2049
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.nfs.id}"
}
