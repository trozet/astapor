class quickstack::neutron::controller (
  $admin_email                  = $quickstack::params::admin_email,
  $admin_password               = $quickstack::params::admin_password,
  $ceilometer_metering_secret   = $quickstack::params::ceilometer_metering_secret,
  $ceilometer_user_password     = $quickstack::params::ceilometer_user_password,
  $heat_cfn                     = $quickstack::params::heat_cfn,
  $heat_cloudwatch              = $quickstack::params::heat_cloudwatch,
  $heat_user_password           = $quickstack::params::heat_user_password,
  $heat_db_password             = $quickstack::params::heat_db_password,
  $cinder_db_password           = $quickstack::params::cinder_db_password,
  $cinder_user_password         = $quickstack::params::cinder_user_password,
  $glance_db_password           = $quickstack::params::glance_db_password,
  $glance_user_password         = $quickstack::params::glance_user_password,
  $horizon_secret_key           = $quickstack::params::horizon_secret_key,
  $keystone_admin_token         = $quickstack::params::keystone_admin_token,
  $keystone_db_password         = $quickstack::params::keystone_db_password,
  $metadata_proxy_shared_secret = $quickstack::params::metadata_proxy_shared_secret,
  $mysql_root_password          = $quickstack::params::mysql_root_password,
  $neutron_db_password          = $quickstack::params::neutron_db_password,
  $neutron_user_password        = $quickstack::params::neutron_user_password,
  $neutron_core_plugin          = $quickstack::params::neutron_core_plugin,
  # ovs config
  $bridge_interface             = $quickstack::params::external_interface,
  $enable_ovs_agent             = $quickstack::params::enable_ovs_agent,
  $ovs_vlan_ranges              = $quickstack::params::ovs_vlan_ranges,
  $ovs_bridge_mappings          = $quickstack::params::ovs_bridge_mappings,
  $ovs_bridge_uplinks           = $quickstack::params::ovs_bridge_uplinks,
  $tenant_network_type          = $quickstack::params::tenant_network_type,
  # cisco config
  $cisco_vswitch_plugin         = $quickstack::params::cisco_vswitch_plugin,
  $cisco_nexus_plugin           = $quickstack::params::cisco_nexus_plugin,
  $nexus_credentials            = $quickstack::params::nexus_credentials,
  
  $nova_db_password             = $quickstack::params::nova_db_password,
  $nova_user_password           = $quickstack::params::nova_user_password,
  $controller_priv_floating_ip  = $quickstack::params::controller_priv_floating_ip,
  $controller_pub_floating_ip   = $quickstack::params::controller_pub_floating_ip,
  $verbose                      = $quickstack::params::verbose
) inherits quickstack::params {

    class {'openstack::db::mysql':
        mysql_root_password  => $mysql_root_password,
        keystone_db_password => $keystone_db_password,
        glance_db_password   => $glance_db_password,
        nova_db_password     => $nova_db_password,
        cinder_db_password   => $cinder_db_password,
        neutron_db_password  => $neutron_db_password,

        # MySQL
        mysql_bind_address     => '0.0.0.0',
        mysql_account_security => true,

        # neutron
        neutron                => true,

        allowed_hosts          => ['%',$controller_priv_floating_ip],
        enabled                => true,
    }

    class {'qpid::server':
        auth => "no"
    }

    class {'openstack::keystone':
        db_host               => $controller_priv_floating_ip,
        db_password           => $keystone_db_password,
        admin_token           => $keystone_admin_token,
        admin_email           => $admin_email,
        admin_password        => $admin_password,
        glance_user_password  => $glance_user_password,
        nova_user_password    => $nova_user_password,
        cinder_user_password  => $cinder_user_password,
        neutron_user_password => $neutron_user_password,
        public_address        => $controller_pub_floating_ip,
        admin_address         => $controller_priv_floating_ip,
        internal_address      => $controller_priv_floating_ip,
        neutron               => false,
        enabled               => true,
        require               => Class['openstack::db::mysql'],
    }

    class { 'swift::keystone::auth':
        password => $swift_admin_password,
        address  => $controller_priv_floating_ip,
    }

    class { 'ceilometer::keystone::auth':
        password => $ceilometer_user_password,
        public_address => $controller_priv_floating_ip,
        admin_address => $controller_priv_floating_ip,
        internal_address => $controller_priv_floating_ip,
    }

    class {'openstack::glance':
        db_host        => $controller_priv_floating_ip,
        user_password  => $glance_user_password,
        db_password    => $glance_db_password,
        require        => Class['openstack::db::mysql'],
    }

    # Configure Nova
    class { 'nova':
        sql_connection     => "mysql://nova:${nova_db_password}@${controller_priv_floating_ip}/nova",
        image_service      => 'nova.image.glance.GlanceImageService',
        glance_api_servers => "http://${controller_priv_floating_ip}:9292/v1",
        rpc_backend        => 'nova.openstack.common.rpc.impl_qpid',
        verbose            => $verbose,
        require            => Class['openstack::db::mysql', 'qpid::server'],
    }

    class { 'nova::api':
        enabled           => true,
        admin_password    => $nova_user_password,
        auth_host         => $controller_priv_floating_ip,
        neutron_metadata_proxy_shared_secret => $metadata_proxy_shared_secret,
    }

    nova_config {
        'DEFAULT/auto_assign_floating_ip': value => 'True';
        'DEFAULT/multi_host':              value => 'True';
        'DEFAULT/force_dhcp_release':      value => 'False';

        'keystone_authtoken/admin_tenant_name': value => 'admin';
        'keystone_authtoken/admin_user':        value => 'admin';
        'keystone_authtoken/admin_password':    value => $admin_password;
        'keystone_authtoken/auth_host':         value => '127.0.0.1';  
    }

    class { [ 'nova::scheduler', 'nova::cert', 'nova::consoleauth', 'nova::conductor' ]:
        enabled => true,
    }

    class { 'nova::vncproxy':
        host    => '0.0.0.0',
        enabled => true,
    }

    # Configure Ceilometer
    class { 'mongodb':
       enable_10gen => false,
       port         => '27017',
    }

    class { 'ceilometer':
        metering_secret => $ceilometer_metering_secret,
        qpid_hostname   => $controller_priv_floating_ip,
        rpc_backend     => 'ceilometer.openstack.common.rpc.impl_qpid',
        verbose         => $verbose,
    }

    class { 'ceilometer::db':
        database_connection => 'mongodb://localhost:27017/ceilometer',
        require             => Class['mongodb'],
    }

    class { 'ceilometer::collector':
        require => Class['ceilometer::db'],
    }

    class { 'ceilometer::agent::central':
        auth_url      => "http://${controller_priv_floating_ip}:35357/v2.0",
        auth_password => $ceilometer_user_password,
    }

    class { 'ceilometer::api':
        keystone_host     => $controller_priv_floating_ip,
        keystone_password => $ceilometer_user_password,
        require           => Class['mongodb'],
    }

    glance_api_config {
        'DEFAULT/notifier_strategy': value => 'qpid'
    }

    class { 'quickstack::cinder_controller':
      cinder_db_password          => $cinder_db_password,
      cinder_user_password        => $cinder_user_password,
      controller_priv_floating_ip => $controller_priv_floating_ip,
      verbose                     => $verbose,
    }

    class { 'quickstack::heat_controller':
      heat_cfn                    => $heat_cfn,
      heat_cloudwatch             => $heat_cloudwatch,
      heat_user_password          => $heat_user_password,
      heat_db_password            => $heat_db_password,
      controller_priv_floating_ip => $controller_priv_floating_ip,
      verbose                     => $verbose,
    }

    package {'horizon-packages':
        name   => ['python-memcached', 'python-netaddr'],
        notify => Class['horizon'],
    }

    file {'/etc/httpd/conf.d/rootredirect.conf':
        ensure  => present,
        content => 'RedirectMatch ^/$ /dashboard/',
        notify  => File['/etc/httpd/conf.d/openstack-dashboard.conf'],
    }

    class {'horizon':
        secret_key    => $horizon_secret_key,
        keystone_host => $controller_priv_floating_ip,
    }

    class {'memcached':}

    class { '::neutron':
        enabled               => true,
        verbose               => true,
        allow_overlapping_ips => true,
        rpc_backend           => 'neutron.openstack.common.rpc.impl_qpid',
        qpid_hostname         => $controller_priv_floating_ip,
    }

    neutron_config {
        'database/connection': value => "mysql://neutron:${neutron_db_password}@${controller_priv_floating_ip}/neutron";
    }

    class { '::neutron::keystone::auth':
        password         => $admin_password,
        public_address   => $controller_pub_floating_ip,
        admin_address    => $controller_priv_floating_ip,
        internal_address => $controller_priv_floating_ip,
    }

    class { '::neutron::server':
        auth_host        => $::ipaddress,
        auth_password    => $admin_password,
     }

    if $neutron_core_plugin == 'ovs' {
      $core_plugin_real = 'neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2

      neutron_plugin_ovs {
          'OVS/enable_tunneling': value => 'True';
          'SECURITYGROUP/firewall_driver':
          value => 'neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver';
      }

      class { '::neutron::plugins::ovs':
          sql_connection      => "mysql://neutron:${neutron_db_password}@${controller_priv_floating_ip}/neutron",
          tenant_network_type => 'gre',
      }
    }

    if $neutron_core_plugin == 'cisco' {
      $core_plugin_real = 'neutron.plugins.cisco.network_plugin.PluginV2'

      if $cisco_vswitch_plugin == 'n1k' {
        $cisco_vswitch_plugin_real = 'neutron.plugins.cisco.n1kv.n1kv_neutron_plugin.N1kvNeutronPluginV2'
      } else {

        $cisco_vswitch_plugin_real = 'neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2'

        if ($ovs_bridge_mappings != []) {
          $br_map_str = join($ovs_bridge_mappings, ',')
          neutron_plugin_ovs {
            'OVS/bridge_mappings': value => $br_map_str;
          }
          neutron::plugins::ovs::bridge{ $ovs_bridge_mappings:
            before => Service['neutron-plugin-ovs-service'],
          }
          neutron::plugins::ovs::port{ $ovs_bridge_uplinks:
            before => Service['neutron-plugin-ovs-service'],
          }
        }

        neutron_plugin_ovs {
          'OVS/bridge_mappings': value => $br_map_str;
        }

        class { '::neutron::plugins::ovs':
          sql_connection      => "mysql://neutron:${neutron_db_password}@${controller_priv_floating_ip}/neutron",
          tenant_network_type => $tenant_network_type,
          network_vlan_ranges => $ovs_vlan_ranges,
        }
      }

      if $cisco_nexus_plugin == 'nexus' {
        $cisco_nexus_plugin_real = 'neutron.plugins.cisco.nexus.cisco_nexus_plugin_v2.NexusPlugin'

        package { 'python-ncclient':
          ensure => installed,
        } ~> Service['neutron-server']


        neutron_plugin_cisco<||> ->
        file {'/etc/neutron/plugins/cisco/cisco_plugins.ini':
          owner => 'root',
          group => 'root',
          content => template('cisco_plugins.ini.erb')
        } ~> Service['neutron-server']
      } else {
        $cisco_nexus_plugin_real = undef
      }

      if $nexus_credentials {
        file {'/var/lib/neutron/.ssh':
          ensure => directory,
          owner  => 'neutron',
          require => Package['neutron-server']
        }
        nexus_creds{ $nexus_credentials:
          require => File['/var/lib/neutron/.ssh']
        }
      }

      class { '::neutron::plugins::cisco':
        database_user     => $neutron_db_user,
        database_pass     => $neutron_db_password,
        database_host     => $controller_priv_floating_ip,
        keystone_password => $admin_password,
        keystone_auth_url => "http://${controller_priv_floating_ip}:35357/v2.0/",
        vswitch_plugin    => $cisco_vswitch_plugin_real,
        nexus_plugin      => $cisco_nexus_plugin_real
      }
    }
    
    class { '::nova::network::neutron':
        neutron_admin_password    => $neutron_user_password,
    }

    firewall { '001 controller incoming':
        proto    => 'tcp',
        dport    => ['80', '443', '3260', '3306', '5000', '35357', '5672', '8773', '8774', '8775', '8776', '9292', '6080', '9696'],   
        action   => 'accept',
    }

    if ($::selinux != "false"){
      selboolean { 'httpd_can_network_connect':
          value => on,
          persistent => true,
      }
    }
}

define nexus_creds {
  $args = split($title, '/')
  neutron_plugin_cisco_credentials {
    "${args[0]}/username": value => $args[1];
    "${args[0]}/password": value => $args[2];
  }
  exec {"${title}":
    unless => "/bin/cat /var/lib/neutron/.ssh/known_hosts | /bin/grep ${args[0]}",
    command => "/usr/bin/ssh-keyscan -t rsa ${args[0]} >> /var/lib/neutron/.ssh/known_hosts",
    user    => 'neutron',
    require => Package['neutron-server']
  }
}

