class quickstack::pacemaker::keystone (
  $admin_email,
  $admin_password,
  $admin_tenant     = "admin",
  $admin_token,
  $db_name          = "keystone",
  $db_password,
  $db_ssl           = "false",
  $db_ssl_ca        = undef,
  $db_type          = "mysql",
  $db_user          = "keystone",
  $debug            = "false",
  $enabled          = "true",
  $idle_timeout     = "200",
  $keystonerc       = "false",
  $public_protocol  = "http",
  $region           = "RegionOne",
  $token_driver     = "keystone.token.backends.sql.Token",
  $token_format     = "PKI",
  $use_syslog       = "false",
  $log_facility     = 'LOG_USER',
  $verbose          = 'false',
  $ceilometer       = "false",
  $cinder           = "true",
  $glance           = "true",
  $heat             = "false",
  $heat_cfn         = "false",
  $nova             = "true",
  $neutron          = "true",
  $swift            = "false",
) {

  include quickstack::pacemaker::common

  if (map_params('include_keystone') == 'true') {

    Class['::quickstack::pacemaker::common'] ->
    class { "::quickstack::pacemaker::vip::keystone":
      keystone_public_vip  => map_params("keystone_public_vip"),
      keystone_private_vip => map_params("keystone_private_vip"),
      keystone_admin_vip   => map_params("keystone_admin_vip"),
      keystone_group       => map_params("keystone_group"),
      notify               => Notify["resource-created-report"],
    }
    ->
    class {'::quickstack::firewall::keystone':}
    ->
    class {"::openstack::keystone":
      admin_email                 => "$admin_email",
      admin_password              => "$admin_password",
      admin_tenant                => "$admin_tenant",
      admin_token                 => "$admin_token",
      bind_host                   => map_params("local_bind_addr"),
      db_host                     => map_params("db_vip"),
      db_name                     => "$db_name",
      db_password                 => "$db_password",
      db_ssl                      => "$db_ssl",
      db_ssl_ca                   => "$db_ssl_ca",
      db_type                     => "$db_type",
      db_user                     => "$db_user",
      debug                       => "$debug",
      enabled                     => "$enabled",
      idle_timeout                => "$idle_timeout",
      public_protocol             => "$public_protocol",
      region                      => "$region",
      token_driver                => "$token_driver",
      token_format                => "$token_format",
      verbose                     => "$verbose",
      public_address              => map_params("keystone_public_vip"),
      internal_address            => map_params("keystone_private_vip"),
      admin_address               => map_params("keystone_admin_vip"),
      nova                        => "$nova",
      nova_user_password          => map_params("nova_user_password"),
      nova_public_address         => map_params("nova_public_vip"),
      nova_internal_address       => map_params("nova_private_vip"),
      nova_admin_address          => map_params("nova_admin_vip"),
      glance                      => "$glance",
      glance_user_password        => map_params("glance_user_password"),
      glance_public_address       => map_params("glance_public_vip"),
      glance_internal_address     => map_params("glance_private_vip"),
      glance_admin_address        => map_params("glance_admin_vip"),
      cinder                      => "$cinder",
      cinder_user_password        => map_params("cinder_user_password"),
      cinder_public_address       => map_params("cinder_public_vip"),
      cinder_internal_address     => map_params("cinder_private_vip"),
      cinder_admin_address        => map_params("cinder_admin_vip"),
      neutron                     => "$neutron",
      neutron_user_password       => map_params("neutron_user_password"),
      neutron_public_address      => map_params("neutron_public_vip"),
      neutron_internal_address    => map_params("neutron_private_vip"),
      neutron_admin_address       => map_params("neutron_admin_vip"),
      ceilometer                  => "$ceilometer",
      ceilometer_user_password    => map_params("ceilometer_user_password"),
      ceilometer_public_address   => map_params("ceilometer_public_vip"),
      ceilometer_internal_address => map_params("ceilometer_private_vip"),
      ceilometer_admin_address    => map_params("ceilometer_admin_vip"),
      swift                       => "$swift",
      swift_user_password         => map_params("swift_user_password"),
      swift_public_address        => map_params("swift_public_vip"),
      swift_internal_address      => map_params("swift_private_vip"),
      swift_admin_address         => map_params("swift_admin_vip"),
      use_syslog                  => "$use_syslog",
      log_facility                => "$log_facility",
      # This will be correct once o-p-m gets a modern heat module
      #heat                        => "$heat",
      #heat_user_password          => map_params("heat_user_password"),
      #heat_public_address         => map_params("heat_public_vip"),
      #heat_internal_address       => map_params("heat_private_vip"),
      #heat_admin_address          => map_params("heat_admin_vip"),
      #heat_cfn                    => "$heat_cfn",
      #heat_cfn_user_password      => map_params("heat_cfn_user_password"),
      #heat_cfn_public_address     => map_params("heat_cfn_public_vip"),
      #heat_cfn_internal_address   => map_params("heat_cfn_private_vip"),
      #heat_cfn_admin_address      => map_params("heat_cfn_admin_vip"),

    }
    # TODO: get heat working (we may get this free if the heat puppet code
    # is updated in o-p-m
    #->
    #class {"heat::keystone::auth":
    #  password              => map_params("heat_user_password"),
    #  heat_public_address   => map_params("heat_public_vip"),
    #  heat_internal_address => map_params("heat_private_vip"),
    #  heat_admin_address    => map_params("heat_admin_vip"),
    #  cfn_public_address    => map_params("heat_cfn_public_vip"),
    #  cfn_internal_address  => map_params("heat_cfn_private_vip"),
    #  cfn_admin_address     => map_params("heat_cfn_admin_vip"),

    #}
    ->
    pacemaker::resource::lsb {'openstack-keystone':
      group => map_params("keystone_group"),
      clone => true,
    }
    ->
    class { "::quickstack::pacemaker::rsync::keystone":
      keystone_private_vip => map_params("keystone_private_vip"),
      keystone_group       => map_params("keystone_group"),
    }
    ->
    class {"::quickstack::load_balancer::keystone":
      frontend_pub_host    => map_params("keystone_public_vip"),
      frontend_priv_host   => map_params("keystone_private_vip"),
      frontend_admin_host  => map_params("keystone_admin_vip"),
      backend_server_names => map_params("lb_backend_server_names"),
      backend_server_addrs => map_params("lb_backend_server_addrs"),
    }
    ~>
    Service['keystone']
    # TODO: Consider if we should pre-emptively purge any directories keystone has
    # created in /tmp

    if "$keystonerc" == "true" {
      class { '::quickstack::admin_client':
        admin_password        => "$admin_password",
        controller_admin_host => map_params("keystone_admin_vip"),
      }
    }

    notify {"resource-created-report":
      message => "Resource ip for keystone created",
    }
  }
}
