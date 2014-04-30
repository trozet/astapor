class quickstack::pacemaker::mysql (
  $mysql_root_password = '',
  $storage_device      = '',
  $storage_type        = '',
  $storage_options     = '',
) {
  include quickstack::pacemaker::common

  if (map_params('include_mysql') == 'true') {
    Class['::quickstack::pacemaker::common']
    ->
    quickstack::pacemaker::vips { "mysql":
      public_vip  => map_params("db_vip"),
      private_vip => map_params("db_vip"),
      admin_vip   => map_params("db_vip"),
    }

    class {'quickstack::hamysql::node':
      mysql_root_password          => $mysql_root_password,
      keystone_db_password         => map_params("keystone_db_password"),
      glance_db_password           => map_params("glance_db_password"),
      nova_db_password             => map_params("nova_db_password"),
      cinder_db_password           => map_params("cinder_db_password"),
      heat_db_password             => map_params("heat_db_password"),
      neutron_db_password          => map_params("neutron_db_password"),
      neutron                      => str2bool_i(map_params("neutron")),
      mysql_bind_address           => map_params("local_bind_addr"),
      mysql_virtual_ip             => map_params("db_vip"),
      mysql_virtual_ip_managed     => "false",
      mysql_shared_storage_device  => $storage_device,
      mysql_shared_storage_type    => $storage_type,
      mysql_shared_storage_options => $storage_options,
      mysql_resource_group_name    => map_params("db_group"),
      corosync_setup               => false,
      mysql_virt_ip_nic            => '',
      mysql_virt_ip_cidr_mask      => '32',
    }
    ->
    class {"::quickstack::load_balancer::mysql":
      frontend_pub_host    => map_params("db_vip"),
      backend_server_names => map_params("lb_backend_server_names"),
      backend_server_addrs => map_params("lb_backend_server_addrs"),
    }

    if str2bool_i("$hamysql_is_running") {
      Class ['quickstack::hamysql::node'] ->
      exec {"mysql-has-users":
        timeout   => 3600,
        tries     => 360,
        try_sleep => 10,
        command   => "/tmp/ha-all-in-one-util.bash property_exists mysql",
      }
      if str2bool_i("$hamysql_active_node") {
        Exec["pcs-mysql-server-set-up"] -> Exec["mysql-has-users"]
      }
    }
    Exec['stonith-setup-complete'] -> Pacemaker::Resource::Filesystem['mysql-clu-fs']
  }
}
