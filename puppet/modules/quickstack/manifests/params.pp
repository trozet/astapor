class quickstack::params {
  $verbose                    = 'true'

  $heat_cfn                   = 'false'
  $heat_cloudwatch            = 'false'

  # Passwords are currently changed to decent strings by sed
  # during the setup process. This will move to the Foreman API v2
  # at some point.
  $admin_password             = 'CHANGEME'
  $ceilometer_metering_secret = 'CHANGEME'
  $ceilometer_user_password   = 'CHANGEME'
  $heat_user_password         = 'CHANGEME'
  $heat_db_password           = 'CHANGEME'
  $cinder_db_password         = 'CHANGEME'
  $cinder_user_password       = 'CHANGEME'
  $glance_db_password         = 'CHANGEME'
  $glance_user_password       = 'CHANGEME'
  $horizon_secret_key         = 'CHANGEME'
  $keystone_admin_token       = 'CHANGEME'
  $keystone_db_password       = 'CHANGEME'
  $mysql_root_password        = 'CHANGEME'
  $neutron_db_password        = 'CHANGEME'
  $neutron_user_password      = 'CHANGEME'
  $nova_db_password           = 'CHANGEME'
  $nova_user_password         = 'CHANGEME'

  # Networking
  $private_interface             = 'PRIV_INTERFACE'
  $public_interface              = 'PUB_INTERFACE'
  $fixed_network_range           = 'PRIV_RANGE'
  $floating_network_range        = 'PUB_RANGE'
  $controller_priv_floating_ip   = 'PRIV_IP'
  $controller_pub_floating_ip    = 'PUB_IP'
  $metadata_proxy_shared_secret  = 'CHANGEME'
  $bridge_interface              = 'PRIV_IP'
  $enable_ovs_agent              = 'true'
  $ovs_vlan_ranges               = undef
  $ovs_bridge_mappings           = [undef]
  $ovs_bridge_uplinks            = [undef]
  $tenant_network_type           = 'gre'

  # neutron plugin config
  $neutron_core_plugin           = 'neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2'
  # If using the Cisco plugin, use either OVS or n1k for virtualised l2
  $cisco_vswitch_plugin          = 'neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2'
  # If using the Cisco plugin, Nexus hardware can be used for l2
  $cisco_nexus_plugin            = 'neutron.plugins.cisco.nexus.cisco_nexus_plugin_v2.NexusPlugin'
  $nexus_credentials             = ['1.1.1.1/nexus_username1/secret1',
                                    '2.2.2.2/nexus_username2/secret2']
  # Logs
  $admin_email                = "admin@${::domain}"
}
