class quickstack::cinder(
  $user_password  = 'cinder',
  $bind_host      = '0.0.0.0',
  $db_host        = '127.0.0.1',
  $db_name        = 'cinder',
  $db_user        = 'cinder',
  $db_password    = '',
  $db_ssl         = false,
  $db_ssl_ca      = '',
  $glance_host    = '127.0.0.1',
  $keystone_host  = '127.0.0.1',
  $qpid_heartbeat = '60',
  $qpid_host      = '127.0.0.1',
  $qpid_port      = '5672',
  $qpid_username  = '',
  $qpid_password  = '',
  $use_syslog     = false,
  $log_facility   = 'LOG_USER',

  $enabled        = true,
  $debug          = false,
  $verbose        = false,
) {
  include ::quickstack::firewall::cinder

  $qpid_password_safe_for_cinder = $qpid_password ? {
    ''      => 'guest',
    false   => 'guest',
    default => $qpid_password,
  }

  cinder_config {
    'DEFAULT/glance_host': value => $glance_host;
    'DEFAULT/notification_driver': value => 'cinder.openstack.common.notifier.rpc_notifier'
  }

  if str2bool_i("$db_ssl") {
    $sql_connection = "mysql://${db_user}:${db_password}@${db_host}/${db_name}?ssl_ca=${db_ssl_ca}"
  } else {
    $sql_connection = "mysql://${db_user}:${db_password}@${db_host}/${db_name}"
  }

  class {'::cinder':
    rpc_backend    => 'cinder.openstack.common.rpc.impl_qpid',
    qpid_hostname  => $qpid_host,
    qpid_port      => $qpid_port,
    qpid_username  => $qpid_username,
    qpid_password  => $qpid_password_safe_for_cinder,
    qpid_heartbeat => $qpid_heartbeat,
    sql_connection => $sql_connection,
    verbose        => str2bool_i("$verbose"),
    use_syslog     => str2bool_i("$use_syslog"),
    log_facility   => $log_facility,
  }

  class {'::cinder::api':
    keystone_password  => $user_password,
    keystone_tenant    => "services",
    keystone_user      => "cinder",
    keystone_auth_host => $keystone_host,
    enabled            => str2bool_i("$enabled"),
    bind_host          => $bind_host,
  }

  class {'::cinder::scheduler':
    enabled => str2bool_i("$enabled"),
  }
}
