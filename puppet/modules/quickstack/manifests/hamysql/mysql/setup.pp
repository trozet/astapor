class quickstack::hamysql::mysql::setup (
  $keystone_db_password,
  $glance_db_password,
  $nova_db_password,
  $cinder_db_password,
  $mysql_bind_address     = '0.0.0.0',
  # Keystone
  $keystone_db_user       = 'keystone',
  $keystone_db_dbname     = 'keystone',
  # Glance
  $glance_db_user         = 'glance',
  $glance_db_dbname       = 'glance',
  # Nova
  $nova_db_user           = 'nova',
  $nova_db_dbname         = 'nova',
  # Cinder
  $cinder                 = true,
  $cinder_db_user         = 'cinder',
  $cinder_db_dbname       = 'cinder',
  # neutron
  $neutron                = true,
  $neutron_db_user        = 'neutron',
  $neutron_db_dbname      = 'neutron',

  # TODO's:
  #  -mysql bind only on its vip, not 0.0.0.0
  #  -mysql account security
  #  -parameterize cluster member IP's
  #  -parameterize vip
) {

  if str2bool("$hamysql_active_node") {
    # TODO use IP other than 127.0.0.1 if $mysql_bind_address is not 0.0.0.0
    database { $keystone_db_dbname:
      ensure   => 'present',
      provider => 'mysql',
      require  => Class['quickstack::hamysql::mysql::rootpw'],
    }
    database_user { "$keystone_db_user@127.0.0.1":
      ensure => 'present',
      password_hash => mysql_password($keystone_db_password),
      provider      => 'mysql',
      require => Database[$keystone_db_dbname],
    }

    database { $glance_db_dbname:
      ensure => 'present',
      provider => 'mysql',
    }
    database_user { "$glance_db_user@127.0.0.1":
      ensure => 'present',
      password_hash => mysql_password($glance_db_password),
      provider      => 'mysql',
      require => Database[$glance_db_dbname],
    }

    database { $nova_db_dbname:
      ensure => 'present',
      provider => 'mysql',
    }
    database_user { "$nova_db_user@127.0.0.1":
      ensure => 'present',
      password_hash => mysql_password($nova_db_password),
      provider      => 'mysql',
      require => Database[$nova_db_dbname],
    }

    database { $cinder_db_dbname:
      ensure => 'present',
      provider => 'mysql',
    }
    database_user { "$cinder_db_user@127.0.0.1":
      ensure => 'present',
      password_hash => mysql_password($cinder_db_password),
      provider      => 'mysql',
      require => Database[$cinder_db_dbname],
    }
  }
}
