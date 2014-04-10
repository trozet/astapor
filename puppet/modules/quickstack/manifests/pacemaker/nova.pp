class quickstack::pacemaker::nova (
  $auto_assign_floating_ip = 'true',
  $db_name                 = 'nova',
  $db_password,
  $db_user                 = 'nova',
  $default_floating_pool   = 'nova',
  $force_dhcp_release      = 'false',
  $image_service           = 'nova.image.glance.GlanceImageService',
  $memcached_port          = '11211',
  $multi_host              = 'true',
  $neutron                 = 'false',
  $neutron_metadata_proxy_secret,
  $qpid_heartbeat          = '30',
  $rpc_backend             = 'nova.openstack.common.rpc.impl_qpid',
  $verbose                 = 'false',
) {

  include quickstack::pacemaker::common

  if (map_params('include_nova') == 'true') {
    $pcmk_nova_group = map_params("nova_group")
    $memcached_ips =  map_params("lb_backend_server_addrs")
    $memcached_servers = split(
      inline_template('<%= @memcached_ips.map {
        |x| x+":"+@memcached_port }.join(",") %>'),
        ','
    )

    Class['::quickstack::pacemaker::common']
    ->
    quickstack::pacemaker::vips { "$pcmk_nova_group":
      public_vip  => map_params("nova_public_vip"),
      private_vip => map_params("nova_private_vip"),
      admin_vip   => map_params("nova_admin_vip"),
    }
    ->
    exec {"i-am-nova-vip-OR-nova-is-up-on-vip":
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      command   => "/tmp/ha-all-in-one-util.bash i_am_vip $nova_private_vip || /tmp/ha-all-in-one-util.bash property_exists nova",
      unless    => "/tmp/ha-all-in-one-util.bash i_am_vip $nova_private_vip || /tmp/ha-all-in-one-util.bash property_exists nova",
    }
    ->
    class { '::quickstack::nova':
      admin_password                => map_params("nova_user_password"),
      auth_host                     => map_params("keystone_admin_vip"),
      auto_assign_floating_ip       => $auto_assign_floating_ip,
      bind_address                  => map_params("local_bind_addr"),
      db_host                       => map_params("db_vip"),
      db_name                       => $db_name,
      db_password                   => $db_password,
      db_user                       => $db_user,
      default_floating_pool         => $default_floating_pool,
      force_dhcp_release            => $force_dhcp_release,
      glance_host                   => map_params("glance_private_vip"),
      glance_port                   => "${::quickstack::load_balancer::glance::api_port}",
      image_service                 => $image_service,
      memcached_servers             => $memcached_servers,
      multi_host                    => $multi_host,
      neutron                       => map_params("include_neutron"),
      neutron_metadata_proxy_secret => $neutron_metadata_proxy_secret,
      qpid_heartbeat                => $qpid_heartbeat,
      qpid_hostname                 => map_params("qpid_vip"),
      qpid_port                     => map_params("qpid_port"),
      rpc_backend                   => $rpc_backend,
      verbose                       => $verbose,
    }
    ->
    class {"::quickstack::load_balancer::nova":
      frontend_pub_host    => map_params("nova_public_vip"),
      frontend_priv_host   => map_params("nova_private_vip"),
      frontend_admin_host  => map_params("nova_admin_vip"),
      backend_server_names => map_params("lb_backend_server_names"),
      backend_server_addrs => map_params("lb_backend_server_addrs"),
    }
    ->
    exec {"pcs-nova-server-set-up":
      command => "/usr/sbin/pcs property set nova=running --force",
    }
    ->
    pacemaker::resource::lsb {['openstack-nova-consoleauth',
                              'openstack-nova-novncproxy',
                              'openstack-nova-api',
                              'openstack-nova-scheduler',
                              'openstack-nova-conductor' ]:
      group => "$pcmk_glance_group",
      clone => true,
    }
    ->
    pacemaker::constraint::base { 'nova-console-vnc-constr' :
      constraint_type => "order",
      first_resource  => "lsb-openstack-nova-consoleauth-clone",
      second_resource => "lsb-openstack-nova-novncproxy-clone",
      first_action    => "start",
      second_action   => "start",
    }
    ->
    pacemaker::constraint::colocation { 'nova-console-vnc-colo' :
      source => "lsb-openstack-nova-novncproxy-clone",
      target => "lsb-openstack-nova-consoleauth-clone",
      score => "INFINITY",
    }
    ->
    pacemaker::constraint::base { 'nova-vnc-api-constr' :
      constraint_type => "order",
      first_resource  => "lsb-openstack-nova-novncproxy-clone",
      second_resource => "lsb-openstack-nova-api-clone",
      first_action    => "start",
      second_action   => "start",
    }
    ->
    pacemaker::constraint::colocation { 'nova-vnc-api-colo' :
      source => "lsb-openstack-nova-api-clone",
      target => "lsb-openstack-nova-novncproxy-clone",
      score => "INFINITY",
    }
    pacemaker::constraint::base { 'nova-api-scheduler-constr' :
      constraint_type => "order",
      first_resource  => "lsb-openstack-nova-api-clone",
      second_resource => "lsb-openstack-nova-scheduler-clone",
      first_action    => "start",
      second_action   => "start",
    }
    ->
    pacemaker::constraint::colocation { 'nova-api-scheduler-colo' :
      source => "lsb-openstack-nova-scheduler-clone",
      target => "lsb-openstack-nova-api-clone",
      score => "INFINITY",
    }
    ->
    pacemaker::constraint::base { 'nova-scheduler-conductor-constr' :
      constraint_type => "order",
      first_resource  => "lsb-openstack-nova-scheduler-clone",
      second_resource => "lsb-openstack-nova-conductor-clone",
      first_action    => "start",
      second_action   => "start",
    }
  }
}
