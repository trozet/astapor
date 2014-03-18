# A minor variation of openstack::glance
#  - expose $filesystem_store_datadir
#  - default values of '' for swift_store_user and swift_store_key
#    instead of false which is more consistent with existing
#    quickstack manifests and better for foreman Host Group Parameters
#    UI (because a param is either a boolean or a string from
#    Foreman's perspective, not dynamically decided based on whatever
#    the users feels like passing in).

class quickstack::glance (
  $user_password            = 'glance',
  $db_password              = '',
  $db_host                  = '127.0.0.1',
  $keystone_host            = '127.0.0.1',
  $sql_idle_timeout         = '3600',
  $registry_host            = '0.0.0.0',
  $bind_host                = '0.0.0.0',
  $db_ssl                   = false,
  $db_ssl_ca                = '',
  $db_user                  = 'glance',
  $db_name                  = 'glance',
  $backend                  = 'file',
  $rbd_store_user           = '',
  $rbd_store_pool           = 'images',
  $swift_store_user         = '',
  $swift_store_key          = '',
  $swift_store_auth_address = 'http://127.0.0.1:5000/v2.0/',
  $verbose                  = false,
  $debug                    = false,
  $use_syslog               = false,
  $log_facility             = 'LOG_USER',
  $enabled                  = true,
  $filesystem_store_datadir = '/var/lib/glance/images/',
) {

  # Configure the db string
  if $db_ssl == true {
    $sql_connection = "mysql://${db_user}:${db_password}@${db_host}/${db_name}?ssl_ca=${db_ssl_ca}"
  } else {
    $sql_connection = "mysql://${db_user}:${db_password}@${db_host}/${db_name}"
  }

  # Install and configure glance-api
  class { 'glance::api':
    verbose           => $verbose,
    debug             => $debug,
    registry_host     => $registry_host,
    bind_host         => $bind_host,
    auth_type         => 'keystone',
    auth_port         => '35357',
    auth_host         => $keystone_host,
    keystone_tenant   => 'services',
    keystone_user     => 'glance',
    keystone_password => $user_password,
    sql_connection    => $sql_connection,
    sql_idle_timeout  => $sql_idle_timeout,
    use_syslog        => $use_syslog,
    log_facility      => $log_facility,
    enabled           => $enabled,
  }

  # Install and configure glance-registry
  class { 'glance::registry':
    verbose           => $verbose,
    debug             => $debug,
    bind_host         => $bind_host,
    auth_host         => $keystone_host,
    auth_port         => '35357',
    auth_type         => 'keystone',
    keystone_tenant   => 'services',
    keystone_user     => 'glance',
    keystone_password => $user_password,
    sql_connection    => $sql_connection,
    sql_idle_timeout  => $sql_idle_timeout,
    use_syslog        => $use_syslog,
    log_facility      => $log_facility,
    enabled           => $enabled,
  }

  # Configure file storage backend
  if($backend == 'swift') {
    if ! $swift_store_user {
      fail('swift_store_user must be set when configuring swift as the glance backend')
    }
    if ! $swift_store_key {
      fail('swift_store_key must be set when configuring swift as the glance backend')
    }

    class { 'glance::backend::swift':
      swift_store_user                    => $swift_store_user,
      swift_store_key                     => $swift_store_key,
      swift_store_auth_address            => $swift_store_auth_address,
      swift_store_create_container_on_put => true,
    }
  } elsif($backend == 'file') {
    class { 'glance::backend::file':
      filesystem_store_datadir => $filesystem_store_datadir,
    }
  } elsif($backend == 'rbd') {
    class { 'glance::backend::rbd':
      rbd_store_user => $rbd_store_user,
      rbd_store_pool => $rbd_store_pool,
    }
  } else {
    fail("Unsupported backend ${backend}")
  }
}
