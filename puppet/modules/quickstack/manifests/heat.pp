class quickstack::heat(
  $heat_user_password      = 'heat',
  $heat_cfn_user_password  = 'heat',
  $auth_encryption_key     = 'heat',
  $bind_host               = '0.0.0.0',
  $db_host                 = '127.0.0.1',
  $db_name                 = 'heat',
  $db_user                 = 'heat',
  $db_password             = '',
  $db_ssl                  = false,
  $db_ssl_ca               = '',
  $keystone_host           = '127.0.0.1',
  $qpid_heartbeat          = '60',
  $qpid_host               = '127.0.0.1',
  $qpid_port               = '5672',

  $cfn_host                = '127.0.0.1',
  $cloudwatch_host         = '127.0.0.1',

  $use_syslog              = false,
  $log_facility            = 'LOG_USER',

  $enabled                 = true,
  $heat_cfn_enabled        = true,
  $heat_cloudwatch_enabled = true,
  $heat_engine_enabled     = true,
  $debug                   = false,
  $verbose                 = false,
) {

  if str2bool_i("$db_ssl") {
    $sql_connection = "mysql://${db_user}:${db_password}@${db_host}/${db_name}?ssl_ca=${db_ssl_ca}"
  } else {
    $sql_connection = "mysql://${db_user}:${db_password}@${db_host}/${db_name}"
  }

  class {'::quickstack::firewall::heat':
    heat_cfn_enabled        => $heat_cfn_enabled,
    heat_cloudwatch_enabled => $heat_cloudwatch_enabled,
  }

  class { '::heat':
    sql_connection    => $sql_connection,
    keystone_ec2_uri  => "http://${keystone_host}:35357/v2.0/ec2tokens",
    auth_uri          => "http://${keystone_host}:35357/v2.0",
    keystone_password => $heat_user_password,
    keystone_tenant   => "services",
    keystone_user     => "heat",
    keystone_host     => $keystone_host,
    rpc_backend       => 'heat.openstack.common.rpc.impl_qpid',
    qpid_heartbeat    => $qpid_heartbeat,
    qpid_hostname     => $qpid_host,
    qpid_port         => $qpid_port,
    use_syslog        => str2bool_i("$use_syslog"),
    log_facility      => $log_facility,
    verbose           => $verbose,
    debug             => $debug,
  }

  class { '::heat::api':
    bind_host         => $bind_host,
    enabled           => str2bool_i("$enabled"),
  }

  class { '::heat::api_cfn':
    # Currently api_cfn module doesn't support setting these
    # keystone_password => $heat_cfn_user_password,
    # keystone_user     => "heat-cfn",
    bind_host         => $bind_host,
    enabled           => str2bool_i("$heat_cfn_enabled"),
  }

  class { '::heat::api_cloudwatch':
    bind_host         => $bind_host,
    enabled           => str2bool_i("$heat_cloudwatch_enabled"),
  }

  class { '::heat::engine':
    auth_encryption_key           => $auth_encryption_key,
    heat_metadata_server_url      => "http://${cfn_host}:8000",
    heat_waitcondition_server_url => "http://${cfn_host}:8000/v1/waitcondition",
    heat_watch_server_url         => "http://${cloudwatch_host}:8003",
    enabled                       => str2bool_i("$heat_engine_enabled"),
  }
}
