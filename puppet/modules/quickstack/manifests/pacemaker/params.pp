class quickstack::pacemaker::params (
  $db_vip                    = '',
  $db_group                  = 'db',
  $ceilometer_public_vip     = '',
  $ceilometer_private_vip    = '',
  $ceilometer_admin_vip      = '',
  $ceilometer_group          = 'ceilometer',
  $ceilometer_user_password  = '',
  $cinder_public_vip         = '',
  $cinder_private_vip        = '',
  $cinder_admin_vip          = '',
  $cinder_group              = 'cinder',
  $cinder_user_password      = '',
  $glance_public_vip         = '',
  $glance_private_vip        = '',
  $glance_admin_vip          = '',
  $glance_group              = 'glance',
  $glance_user_password      = '',
  $heat_public_vip           = '',
  $heat_private_vip          = '',
  $heat_admin_vip            = '',
  $heat_group                = 'heat',
  $heat_user_password        = '',
  $heat_cfn_public_vip       = '',
  $heat_cfn_private_vip      = '',
  $heat_cfn_admin_vip        = '',
  $heat_cfn_group            = 'heat_cfn',
  $heat_cfn_user_password    = '',
  $include_glance            = 'true',
  $include_keystone          = 'true',
  $include_neutron           = 'true',
  $include_nova              = 'true',
  $include_qpid              = 'true',
  $loadbalancer_public_vip   = '',
  $loadbalancer_private_vip  = '',
  $loadbalancer_admin_vip    = '',
  $loadbalancer_group        = 'loadbalancer',
  $lb_backend_server_names   = '',
  $lb_backend_server_addrs   = '', # should this and cluster_members be merged?
  $keystone_public_vip       = '',
  $keystone_private_vip      = '',
  $keystone_admin_vip        = '',
  $keystone_group            = 'keystone',
  $keystone_user_password    = '',
  $neutron_public_vip        = '',
  $neutron_private_vip       = '',
  $neutron_admin_vip         = '',
  $neutron_group             = 'neutron',
  $neutron_user_password     = '',
  $nova_public_vip           = '',
  $nova_private_vip          = '',
  $nova_admin_vip            = '',
  $nova_group                = 'nova',
  $nova_user_password        = '',
  $private_ip                = '',
  $private_iface             = '',
  $qpid_port                 = '5672',
  $qpid_vip                  = '',
  $qpid_group                = 'qpid',
  $swift_public_vip          = '',
  $swift_private_vip         = '',
  $swift_admin_vip           = '',
  $swift_user_password       = '',
  $swift_group               = 'swift',
) {
  # If IP is specified per host, prefer that.
  # If interface is specified, this should get pulled per host,
  # or default to hostgroup level interface.
  if ($private_ip != '') {
    $local_bind_addr = "$private_ip"
    notify {"++++++ Looks like we were given an IP: $local_bind_addr ++++++":}
  } else {
    #TODO: extract this out into a function, we use it all over:
    $local_bind_addr = getvar(regsubst("ipaddress_$private_iface", '[.-]', '_', 'G'))
    notify {"------ OK, thanks for the nic, our IP is: $local_bind_addr ----":}
  }

  include quickstack::pacemaker::common
  include quickstack::load_balancer::common
  include quickstack::pacemaker::qpid
  include quickstack::pacemaker::keystone
  include quickstack::pacemaker::glance
  include quickstack::pacemaker::nova
  include quickstack::pacemaker::load_balancer

  Class['::quickstack::pacemaker::common'] ->
  Class['::quickstack::load_balancer::common'] ->
  Class['::quickstack::pacemaker::qpid'] ->
  Class['::quickstack::pacemaker::keystone'] ->
  Class['::quickstack::pacemaker::glance'] ->
  Class['::quickstack::pacemaker::nova'] ->
  Class['::quickstack::pacemaker::load_balancer']
}
