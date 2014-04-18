class quickstack::pacemaker::load_balancer {

  include quickstack::pacemaker::common

  $loadbalancer_group = map_params("loadbalancer_group")

  quickstack::pacemaker::vips { "$loadbalancer_group":
    public_vip  => map_params("loadbalancer_public_vip"),
    private_vip => map_params("loadbalancer_private_vip"),
    admin_vip   => map_params("loadbalancer_admin_vip"),
  } ->

  Service['haproxy'] ->
  exec {"pcs-haproxy-server-set-up-on-this-node":
    command => "/tmp/ha-all-in-one-util.bash update_my_node_property haproxy"
  } ->
  exec {"all-haproxy-nodes-are-up":
    timeout   => 3600,
    tries     => 360,
    try_sleep => 10,
    command   => "/tmp/ha-all-in-one-util.bash all_members_include haproxy",

  } ->
  pacemaker::resource::lsb {'haproxy':
    group => "$loadbalancer_group",
    clone => true,
  }
}
