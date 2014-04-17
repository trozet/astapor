class quickstack::pacemaker::neutron (
  $enable_tunneling              = false,
  $enabled                       = true,
  $external_network_bridge       = 'br-ex',
  $ovs_bridge_mappings           = [],
  $ovs_bridge_uplinks            = [],
  $ovs_tunnel_iface              = '',
  $ovs_tunnel_network            = '',
  $ovs_vlan_ranges               = '',
  $ovs_tunnel_types              = [],
  $tenant_network_type           = 'vlan',
  $tunnel_id_ranges              = '1:1000',
  $verbose                       = 'false',
) {
  include quickstack::pacemaker::common

  if (map_params('include_neutron') == 'true') {
    $neutron_group = map_params("neutron_group")
    $neutron_public_vip = map_params("neutron_public_vip")
    $ovs_nic = find_nic("$ovs_tunnel_network","$ovs_tunnel_iface","")

    if (map_params('include_mysql') == 'true') {
      if str2bool_i("$hamysql_is_running") {
        Exec['mysql-has-users'] -> Exec['i-am-neutron-vip-OR-neutron-is-up-on-vip']
      }
    }
    if (map_params('include_keystone') == 'true') {
      Exec['all-keystone-nodes-are-up'] -> Exec['i-am-neutron-vip-OR-neutron-is-up-on-vip']
    }
    if (map_params('include_swift') == 'true') {
      Exec['all-swift-nodes-are-up'] -> Exec['i-am-neutron-vip-OR-neutron-is-up-on-vip']
    }
    if (map_params('include_cinder') == 'true') {
      Exec['all-cinder-nodes-are-up'] -> Exec['i-am-neutron-vip-OR-neutron-is-up-on-vip']
    }
    if (map_params('include_glance') == 'true') {
      Exec['all-glance-nodes-are-up'] -> Exec['i-am-neutron-vip-OR-neutron-is-up-on-vip']
    }
    if (map_params('include_nova') == 'true') {
      Exec['all-nova-nodes-are-up'] -> Exec['i-am-neutron-vip-OR-neutron-is-up-on-vip']
    }

    Class['::quickstack::pacemaker::common']
    ->
    quickstack::pacemaker::vips { "$neutron_group":
      public_vip  => map_params("neutron_public_vip"),
      private_vip => map_params("neutron_private_vip"),
      admin_vip   => map_params("neutron_admin_vip"),
    }
    ->
    exec {"i-am-neutron-vip-OR-neutron-is-up-on-vip":
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      command   => "/tmp/ha-all-in-one-util.bash i_am_vip $neutron_public_vip || /tmp/ha-all-in-one-util.bash property_exists neutron",
      unless   => "/tmp/ha-all-in-one-util.bash i_am_vip $neutron_public_vip || /tmp/ha-all-in-one-util.bash property_exists neutron",
    }
    ->
    class { 'quickstack::neutron::all':
      neutron_priv_host             => map_params("local_bind_addr"),
      auth_host                     => map_params("keystone_public_vip"),
      enable_tunneling              => $enable_tunneling,
      enabled                       => $enabled,
      external_network_bridge       => $external_network_bridge,
      mysql_host                    => map_params("db_vip"),
      neutron_db_password           => map_params("neutron_db_password"),
      neutron_user_password         => map_params("neutron_user_password"),
      neutron_metadata_proxy_secret => map_params("neutron_metadata_proxy_secret"),
      ovs_bridge_mappings           => $ovs_bridge_mappings,
      ovs_bridge_uplinks            => $ovs_bridge_uplinks,
      ovs_tunnel_iface              => $ovs_nic,
      ovs_vlan_ranges               => $ovs_vlan_ranges,
      ovs_tunnel_types              => $ovs_tunnel_types,
      qpid_host                     => map_params("qpid_vip"),
      tenant_network_type           => $tenant_network_type,
      tunnel_id_ranges              => $tunnel_id_ranges,
      verbose                       => $verbose,
    }
    class {"::quickstack::load_balancer::neutron":
      frontend_pub_host    => map_params("neutron_public_vip"),
      frontend_priv_host    => map_params("neutron_private_vip"),
      frontend_admin_host    => map_params("neutron_admin_vip"),
      backend_server_names => map_params("lb_backend_server_names"),
      backend_server_addrs => map_params("lb_backend_server_addrs"),
      require              => quickstack::pacemaker::vips["$neutron_group"],
    }
    ->
    exec {"pcs-neutron-server-set-up":
      command => "/usr/sbin/pcs property set neutron=running --force",
    } ->
    exec {"pcs-neutron-server-set-up-on-this-node":
      command => "/tmp/ha-all-in-one-util.bash update_my_node_property neutron"
    } ->
    exec {"all-neutron-nodes-are-up":
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      command   => "/tmp/ha-all-in-one-util.bash all_members_include neutron",
    }
    ->
    pacemaker::resource::lsb {'neutron-db-check':
      group => "neutron-agents-pre",
      clone => true,
    }
    ->
    pacemaker::resource::lsb {'neutron-server':
      group => "neutron-agents-pre",
      clone => false,
    }
    ->
    pacemaker::resource::lsb {'neutron-ovs-cleanup':
      group => "neutron-agents-pre",
      clone => false,
    }
    ->
    pacemaker::resource::lsb {'neutron-netns-cleanup':
      group => "neutron-agents-pre",
      clone => false,
    }
    ->
    pacemaker::resource::lsb {'neutron-agent-watch':
      group => "neutron-agents-pre",
      clone => false,
    }
    ->
    pacemaker::resource::lsb {'neutron-openvswitch-agent':
      clone => false,
    }
    ->
    pacemaker::resource::lsb {'neutron-dhcp-agent':
      clone => false,
    }
    ->
    pacemaker::resource::lsb {'neutron-l3-agent':
      clone => false,
    }
    ->
    pacemaker::resource::lsb {'neutron-metadata-agent':
      clone => false,
    }
    ->
    pacemaker::constraint::base { 'neutron-db-server-constr' :
      constraint_type => "order",
      first_resource  => "lsb-neutron-db-check",
      second_resource => "lsb-neutron-server",
      first_action    => "start",
      second_action   => "start",
    }
    ->
    pacemaker::constraint::colocation { 'neutron-db-server-colo' :
      source => "lsb-neutron-server",
      target => "lsb-neutron-db-check",
      score  => "INFINITY",
    }
    ->
    pacemaker::constraint::base { 'neutron-pre-openvswitch-constr' :
      constraint_type => "order",
      first_resource  => "neutron-agents-pre",
      second_resource => "lsb-neutron-openvswitch-agent",
      first_action    => "start",
      second_action   => "start",
    }
    ->
    pacemaker::constraint::colocation { 'neutron-openvswitch-pre-colo' :
      source => "lsb-neutron-openvswitch-agent",
      target => "neutron-agents-pre",
      score  => "INFINITY",
    }
    ->
    pacemaker::constraint::base { 'neutron-openvswitch-dhcp-constr' :
      constraint_type => "order",
      first_resource  => "lsb-neutron-openvswitch-agent",
      second_resource => "lsb-neutron-dhcp-agent",
      first_action    => "start",
      second_action   => "start",
    }
    ->
    pacemaker::constraint::colocation { 'neutron-openvswitch-dhcp-colo' :
      source => "lsb-neutron-dhcp-agent",
      target => "lsb-neutron-openvswitch-agent",
      score  => "INFINITY",
    }
    ->
    pacemaker::constraint::base { 'neutron-openvswitch-l3-constr' :
      constraint_type => "order",
      first_resource  => "lsb-neutron-openvswitch-agent",
      second_resource => "lsb-neutron-l3-agent",
      first_action    => "start",
      second_action   => "start",
    }
    ->
    pacemaker::constraint::colocation { 'neutron-openvswitch-l3-colo' :
      source => "lsb-neutron-l3-agent",
      target => "lsb-neutron-openvswitch-agent",
      score  => "INFINITY",
    }
    ->
    pacemaker::constraint::base { 'neutron-openvswitch-metadata-constr' :
      constraint_type => "order",
      first_resource  => "lsb-neutron-openvswitch-agent",
      second_resource => "lsb-neutron-metadata-agent",
      first_action    => "start",
      second_action   => "start",
    }
    ->
    pacemaker::constraint::colocation { 'neutron-openvswitch-metadata-colo' :
      source => "lsb-neutron-metadata-agent",
      target => "lsb-neutron-openvswitch-agent",
      score  => "INFINITY",
    }
  }
}
