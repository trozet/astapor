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

  # Networking - we're assuming /24 ranges, but the user can always override
  $public_interface           = 'PRIMARY'
  $private_interface          = 'SECONDARY'
  $fixed_network_range        = inline_template("<%= scope.lookupvar('::network_${private_interface}') + '/24' %>")
  $floating_network_range     = inline_template("<%= scope.lookupvar('::network_${public_interface}') + '/24' %>")
  $pacemaker_priv_floating_ip = 'PRIV_IP'
  $pacemaker_pub_floating_ip  = 'PUB_IP'

  # Logs
  $admin_email                = "admin@${::domain}"
}
