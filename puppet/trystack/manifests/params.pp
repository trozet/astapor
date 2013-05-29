class trystack::params {
  $verbose                    = 'true'

  # Passwords are currently changed to decent strings by sed
  # during the setup process. This will move to the Foreman API v2
  # at some point.
  $admin_password             = 'CHANGEME'
  $cinder_db_password         = 'CHANGEME'
  $cinder_user_password       = 'CHANGEME'
  $glance_db_password         = 'CHANGEME'
  $glance_user_password       = 'CHANGEME'
  $horizon_secret_key         = 'CHANGEME'
  $keystone_admin_token       = 'CHANGEME'
  $keystone_db_password       = 'CHANGEME'
  $mysql_root_password        = 'CHANGEME'
  $nova_db_password           = 'CHANGEME'
  $nova_user_password         = 'CHANGEME'

  # Networking
  $private_interface          = 'eth1'
  $public_interface           = 'eth0'
  $fixed_network_range        = inline_template("<%= scope.lookupvar('::network_${private_interface}') + '/' + scope.lookupvar('::netmask_${private_interface}') %>")
  $floating_network_range     = inline_template("<%= scope.lookupvar('::network_${public_interface}') + '/' + scope.lookupvar('::netmask_${public_interface}') %>")
  $pacemaker_priv_floating_ip = inline_template("<%= scope.lookupvar('::ipaddress_${private_interface}') %>")
  $pacemaker_pub_floating_ip  = inline_template("<%= scope.lookupvar('::ipaddress_${public_interface}') %>")

  # Logs
  $admin_email                = "admin@${::domain}"
}
