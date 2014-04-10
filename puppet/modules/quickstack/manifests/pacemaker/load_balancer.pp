class quickstack::pacemaker::load_balancer {

  $loadbalancer_group = map_params("loadbalancer_group")

  quickstack::pacemaker::vips { "$loadbalancer_group":
    public_vip  => map_params("loadbalancer_public_vip"),
    private_vip => map_params("loadbalancer_private_vip"),
    admin_vip   => map_params("loadbalancer_admin_vip"),
  }
  ->
  pacemaker::resource::lsb {'haproxy':
    group => "$loadbalancer_group",
    clone => true,
  }
}
