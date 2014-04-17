class quickstack::neutron::all (
  $auth_host                     = 'localhost',
  $auth_tenant                   = 'services',
  $auth_user                     = 'neutron',
  $cisco_nexus_plugin            = '',
  $cisco_vswitch_plugin          = '',
  $enable_tunneling              = true,
  $enabled                       = true,
  $external_network_bridge       = 'br-ex',
  $ml2_install_deps              = true,
  $ml2_type_drivers              = ['local', 'flat', 'vlan', 'gre', 'vxlan'],
  $ml2_tenant_network_types      = ['local', 'flat', 'vlan', 'gre', 'vxlan'],
  $ml2_mechanism_drivers         = ['openvswitch'],
  $ml2_flat_networks             = ['*'],
  $ml2_network_vlan_ranges       = ['10:50'],
  $ml2_tunnel_id_ranges          = ['20:100'],
  $ml2_vxlan_group               = '224.0.0.1',
  $ml2_vni_ranges                = ['10:100'],
  $ml2_security_group            = 'dummy',
  $mysql_ca                      = undef,
  $mysql_host                    = '127.0.0.1',
  $neutron_core_plugin           = 'neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2',
  $neutron_db_password,
  $neutron_metadata_proxy_secret,
  $neutron_priv_host             = '127.0.0.1',
  $neutron_user_password,
  $nexus_config                  = '',
  $nexus_credentials             = '',
  $ovs_bridge_mappings           = [],
  $ovs_bridge_uplinks            = [],
  $ovs_tunnel_iface              = '',
  $ovs_tunnel_network            = '',
  $ovs_vlan_ranges               = '',
  $ovs_vxlan_udp_port            = '4789',
  $ovs_tunnel_types              = [],
  $provider_vlan_auto_create     = '',
  $provider_vlan_auto_trunk      = '',
  $qpid_host                     = '127.0.0.1',
  $qpid_username                 = '',
  $qpid_password                 = '',
  $rpc_backend                   = 'neutron.openstack.common.rpc.impl_qpid',
  $tenant_network_type           = 'vlan',
  $tunnel_id_ranges              = '1:1000',
  $verbose                       = 'false',
  $ssl                           = 'false',
) {

  if str2bool_i("$ssl") {
    $qpid_protocol = 'ssl'
    $qpid_port = '5671'
    $sql_connection = "mysql://neutron:${neutron_db_password}@${mysql_host}/neutron?ssl_ca=${mysql_ca}"
  } else {
    $qpid_protocol = 'tcp'
    $qpid_port = '5672'
    $sql_connection = "mysql://neutron:${neutron_db_password}@${mysql_host}/neutron"
  }

  class { '::neutron':
    allow_overlapping_ips => str2bool_i("$allow_overlapping_ips"),
    core_plugin           => $neutron_core_plugin,
    enabled               => str2bool_i("$enabled"),
    rpc_backend           => $rpc_backend,
    qpid_hostname         => $qpid_host,
    qpid_port             => $qpid_port,
    qpid_protocol         => $qpid_protocol,
    qpid_username         => $qpid_username,
    qpid_password         => $qpid_password,
    verbose               => $verbose,
  }
  ->
  # FIXME: This really should be handled by the neutron-puppet module, which has
  # a review request open right now: https://review.openstack.org/#/c/50162/
  # If and when that is merged (or similar), the below can be removed.
  exec { 'neutron-db-manage upgrade':
    command     => 'neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugin.ini upgrade head',
    path        => '/usr/bin',
    user        => 'neutron',
    logoutput   => 'on_failure',
    before      => Service['neutron-server'],
    require     => [Neutron_config['database/connection'], Neutron_config['DEFAULT/core_plugin']],
  }

  class { '::neutron::server':
    auth_host      => $auth_host,
    auth_password  => $neutron_user_password,
    auth_tenant    => $auth_tenant,
    auth_user      => $auth_user,
    connection     => $sql_connection,
  }

  if $neutron_core_plugin == 'neutron.plugins.ml2.plugin.Ml2Plugin' {
    # FIXME: This lovely workaround is because puppet-neutron doesn't
    # install the ml2 package for us, which makes everything else fail.
    # This has been fixed upstream, so we can remove this whole chunk once our
    # puppet rpm deps catch up.
    if str2bool_i("$ml2_install_deps") {
      # test mechanism drivers
      validate_array($ml2_mechanism_drivers)
      if ! $ml2_mechanism_drivers {
        warning('Without networking mechanism driver, ml2 will not communicate with L2 agents')
      }

      # Specific plugin configuration
      # We need this before https://review.openstack.org/#/c/67004/ is
      # merged
      if ('openvswitch' in $ml2_mechanism_drivers) {
        if (!defined(Package['neutron-plugin-ovs'])) {
          package { 'neutron-plugin-ovs':
            ensure => present,
            name   => $::neutron::params::ovs_server_package,
            before => Class['::neutron::plugins::ml2'],
          }
        }
      }
      if ('linuxbridge' in $ml2_mechanism_drivers) {
        if (!defined(Package['neutron-plugin-linuxbridge'])) {
          package { 'neutron-plugin-linuxbridge':
            ensure => present,
            name   => $::neutron::params::linuxbridge_server_package,
            before => Class['::neutron::plugins::ml2'],
          }
        }
      }
    }

    neutron_config {
      'DEFAULT/service_plugins':
        value => join(['neutron.services.l3_router.l3_router_plugin.L3RouterPlugin',]),
    }
    ->
    class { '::neutron::plugins::ml2':
      type_drivers          => $ml2_type_drivers,
      tenant_network_types  => $ml2_tenant_network_types,
      mechanism_drivers     => $ml2_mechanism_drivers,
      flat_networks         => $ml2_flat_networks,
      network_vlan_ranges   => $ml2_network_vlan_ranges,
      tunnel_id_ranges      => $ml2_tunnel_id_ranges,
      vxlan_group           => $ml2_vxlan_group,
      vni_ranges            => $ml2_vni_ranges,
      enable_security_group => $ml2_security_group,
    }
  }

  if $neutron_core_plugin == 'neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2' {

    class { '::neutron::plugins::ovs':
      sql_connection      => $sql_connection,
      tenant_network_type => $tenant_network_type,
      network_vlan_ranges => $ovs_vlan_ranges,
      tunnel_id_ranges    => $tunnel_id_ranges,
      vxlan_udp_port      => $ovs_vxlan_udp_port,
    }
  }

  if $neutron_core_plugin == 'neutron.plugins.cisco.network_plugin.PluginV2' {
    class { 'quickstack::neutron::plugins::cisco':
      neutron_db_password          => $neutron_db_password,
      neutron_user_password        => $neutron_user_password,
      ovs_vlan_ranges              => $ovs_vlan_ranges,
      cisco_vswitch_plugin         => $cisco_vswitch_plugin,
      nexus_config                 => $nexus_config,
      cisco_nexus_plugin           => $cisco_nexus_plugin,
      nexus_credentials            => $nexus_credentials,
      provider_vlan_auto_create    => $provider_vlan_auto_create,
      provider_vlan_auto_trunk     => $provider_vlan_auto_trunk,
      mysql_host                   => $mysql_host,
      mysql_ca                     => $mysql_ca,
      tenant_network_type          => $tenant_network_type,
    }
  }

  class { '::nova::network::neutron':
    neutron_admin_password    => $neutron_user_password,
  }

  $local_ip = find_ip("$ovs_tunnel_network","$ovs_tunnel_iface","")

  class { '::neutron::agents::ovs':
    bridge_uplinks   => $ovs_bridge_uplinks,
    local_ip         => $local_ip,
    bridge_mappings  => $ovs_bridge_mappings,
    enable_tunneling => str2bool_i("$enable_tunneling"),
    tunnel_types     => $ovs_tunnel_types,
    vxlan_udp_port   => $ovs_vxlan_udp_port,
  }

  class { '::neutron::agents::dhcp': }

  class { '::neutron::agents::l3':
    external_network_bridge => $external_network_bridge,
  }

  class { 'neutron::agents::metadata':
    auth_password => $neutron_user_password,
    shared_secret => $neutron_metadata_proxy_secret,
    auth_url      => "http://${auth_host}:35357/v2.0",
    metadata_ip   => $neutron_priv_host,
  }

  #class { 'neutron::agents::lbaas': }

  #class { 'neutron::agents::fwaas': }

  class {'quickstack::neutron::firewall::vxlan':
    port => $ovs_vxlan_udp_port,
  }

  firewall { '001 neutron server (API)':
    proto    => 'tcp',
    dport    => ['9696'],
    action   => 'accept',
  }
}
