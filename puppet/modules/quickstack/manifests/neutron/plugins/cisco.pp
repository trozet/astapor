class quickstack::neutron::plugins::cisco (
  # Set DHCP/L3 Agents on Primary Controller
  $enable_ovs_agent             = false,
  $enable_dhcp_agent            = false,
  $enable_l3_agent              = false,
  $enable_metadata_agent        = false,
  $enable_server                = true,
  $neutron_db_password          = $quickstack::params::neutron_db_password,
  $neutron_user_password        = $quickstack::params::neutron_user_password,
  # ovs config
  $bridge_interface             = $quickstack::params::external_interface,
  $ovs_vlan_ranges              = $quickstack::params::ovs_vlan_ranges,
  $ovs_bridge_mappings          = $quickstack::params::ovs_bridge_mappings,
  $ovs_bridge_uplinks           = $quickstack::params::ovs_bridge_uplinks,
  $tenant_network_type          = 'vlan',
  # cisco config
  $cisco_vswitch_plugin         = $quickstack::params::cisco_vswitch_plugin,
  $cisco_nexus_plugin           = $quickstack::params::cisco_nexus_plugin,
  $nexus_credentials            = $quickstack::params::nexus_credentials,
  $controller_priv_floating_ip  = $quickstack::params::controller_priv_floating_ip,
) inherits quickstack::params {


  if $cisco_vswitch_plugin == 'neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2' {
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

  if $cisco_nexus_plugin == 'neutron.plugins.cisco.nexus.cisco_nexus_plugin_v2.NexusPlugin' {

    package { 'python-ncclient':
      ensure => installed,
    } ~> Service['neutron']

    neutron_plugin_cisco<||> ->
    file {'/etc/neutron/plugins/cisco/cisco_plugins.ini':
      owner => 'root',
      group => 'root',
      content => template('cisco_plugins.ini.erb')
    } ~> Service['neutron']
  }

  if $nexus_credentials {
    file {'/var/lib/neutron/.ssh':
      ensure => directory,
      owner  => 'neutron',
      require => Package['neutron']
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
    vswitch_plugin    => $cisco_vswitch_plugin,
    nexus_plugin      => $cisco_nexus_plugin
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
    require => Package['neutron']
  }
}

