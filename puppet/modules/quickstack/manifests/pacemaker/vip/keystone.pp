# TODO turn this into a defined type, call from each module.
class quickstack::pacemaker::vip::keystone (
  $keystone_public_vip,
  $keystone_private_vip,
  $keystone_admin_vip,
  $keystone_group = 'keystone',
) {

  pacemaker::resource::ip { "ip-$keystone_group-public":
    ip_address => "$keystone_public_vip",
    group      => "$keystone_group",
  }

  pacemaker::resource::ip { "ip-$keystone_group-private":
    ip_address => "$keystone_private_vip",
    group      => "$keystone_group",
  }

  pacemaker::resource::ip { "ip-$keystone_group-admin":
    ip_address => "$keystone_admin_vip",
    group      => "$keystone_group",
  }
}
