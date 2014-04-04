class quickstack::pacemaker::load_balancer (
  $ha_loadbalancer_public_vip,
  $ha_loadbalancer_private_vip,
  $ha_loadbalancer_group,
) {

  $loadbalancer_group = map_params("loadbalancer_group")

  quickstack::pacemaker::vips { "$loadbalancer_group":
    public_vip  => map_params("loadbalancer_public_vip"),
    private_vip => map_params("loadbalancer_private_vip"),
    admin_vip   => map_params("loadbalancer_admin_vip"),
  }
  ->
  pacemaker::resource::lsb {'haproxy':
    group => "$ha_loadbalancer_group",
    clone => true,
  }
}
