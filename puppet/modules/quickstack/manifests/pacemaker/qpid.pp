class quickstack::pacemaker::qpid (
  $config_file           = '/etc/qpidd.conf',
  $package_name          = 'qpid-cpp-server',
  $package_ensure        = present,
  $service_name          = 'qpidd',
  $service_ensure        = running,
  $service_enable        = true,
  $manage_service        = true,
  $backend_port          = '15672',
  $max_connections       = '65535',
  $worker_threads        = '17',
  $connection_backlog    = '10',
  $realm                 = 'QPID',
  $log_to_file           = 'UNSET',
  $haproxy_timeout       = '60s',
  # perhaps we will expose these to params to ::qpid:server soon
  #$auth                  = 'no',
  #$clustered             = false,
  #$cluster_mechanism     = 'ANONYMOUS',
  #$ssl                   = false,
  #$ssl_package_name      = 'qpid-cpp-server-ssl',
  #$ssl_package_ensure    = present,
  #$ssl_backend_port      = '5671',
  #$ssl_ca                = '/etc/ipa/ca.crt',
  #$ssl_cert              = undef,
  #$ssl_key               = undef,
  #$ssl_database_password = undef,
  #$freeipa               = false,
) {

  include quickstack::pacemaker::common

  if (map_params('include_qpid') == 'true') {
    $qpid_group = map_params("qpid_group")

    class {'::quickstack::firewall::qpid':
      ports => [ $backend_port, map_params("qpid_port") ]
    }

    class {'::qpid::server':
      config_file           => $config_file,
      package_name          => $package_name,
      package_ensure        => $package_ensure,
      service_name          => $service_name,
      service_ensure        => $service_ensure,
      service_enable        => $service_enable,
      manage_service        => $manage_service,
      port                  => $backend_port,
      max_connections       => $max_connections,
      worker_threads        => $worker_threads,
      connection_backlog    => $connection_backlog,
      auth                  => 'no',
      realm                 => 'QPID',
      log_to_file           => $log_to_file,
      clustered             => false,
      ssl                   => false,
    }

    class {'::quickstack::load_balancer::qpid':
      frontend_host        => map_params("qpid_vip"),
      backend_server_names => map_params("lb_backend_server_names"),
      backend_server_addrs => map_params("lb_backend_server_addrs"),
      port                 => map_params("qpid_port"),
      backend_port         => $backend_port,
      timeout              => $haproxy_timeout,
    }

    Class['::quickstack::firewall::qpid'] ->
    Class['::qpid::server'] ->
    Class['::quickstack::pacemaker::common'] ->

    # below creates just one vip (not three)
    quickstack::pacemaker::vips { "$qpid_group":
      public_vip  => map_params("qpid_vip"),
      private_vip => map_params("qpid_vip"),
      admin_vip   => map_params("qpid_vip"),
    } ->
    Class['::quickstack::load_balancer::qpid'] ->

    exec {"pcs-qpid-server-set-up-on-this-node":
      command => "/tmp/ha-all-in-one-util.bash update_my_node_property qpid"
    } ->
    exec {"all-qpid-nodes-are-up":
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      command   => "/tmp/ha-all-in-one-util.bash all_members_include qpid",
    } ->
    pacemaker::resource::lsb { 'qpidd':
      group   => 'openstack_qpid',
      clone   => true,
    }
  }
}
