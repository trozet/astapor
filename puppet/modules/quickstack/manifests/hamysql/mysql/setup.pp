class quickstack::hamysql::mysql::setup (
  $keystone_db_password,
  $glance_db_password,
  $nova_db_password,
  $cinder_db_password,
  $heat_db_password,
  $neutron_db_password,
  # Keystone
  $keystone_db_user       = 'keystone',
  $keystone_db_dbname     = 'keystone',
  # Glance
  $glance_db_user         = 'glance',
  $glance_db_dbname       = 'glance',
  # Nova
  $nova_db_user           = 'nova',
  $nova_db_dbname         = 'nova',
  # Heat
  $heat_db_user           = 'heat',
  $heat_db_dbname         = 'heat',
  # Cinder
  $cinder                 = true,
  $cinder_db_user         = 'cinder',
  $cinder_db_dbname       = 'cinder',
  # neutron
  $neutron                = true,
  $neutron_db_user        = 'neutron',
  $neutron_db_dbname      = 'neutron',
) {

  if str2bool_i("$hamysql_active_node") {
    class { 'quickstack::hamysql::mysql::account_security': }

    mysql_database { $keystone_db_dbname:
      ensure   => 'present',
      provider => 'mysql',
      require  => Class['quickstack::hamysql::mysql::rootpw'],
    }
    mysql_user { "$keystone_db_user@%":
      ensure => 'present',
      password_hash => mysql_password("$keystone_db_password"),
      provider      => 'mysql',
      require => Mysql_database[$keystone_db_dbname],
    }
    mysql_grant { "$keystone_db_user@%/$keystone_db_dbname":
      privileges => 'all',
      provider   => 'mysql',
      require    => Mysql_user["$keystone_db_user@%"]
    }

    mysql_database { $glance_db_dbname:
      ensure => 'present',
      provider => 'mysql',
    }
    mysql_user { "$glance_db_user@%":
      ensure => 'present',
      password_hash => mysql_password("$glance_db_password"),
      provider      => 'mysql',
      require => Mysql_database[$glance_db_dbname],
    }
    mysql_grant { "$glance_db_user@%/$glance_db_dbname":
      privileges => 'all',
      provider   => 'mysql',
      require    => Mysql_user["$glance_db_user@%"]
    }

    mysql_database { $nova_db_dbname:
      ensure => 'present',
      provider => 'mysql',
    }
    mysql_user { "$nova_db_user@%":
      ensure => 'present',
      password_hash => mysql_password("$nova_db_password"),
      provider      => 'mysql',
      require => Mysql_database[$nova_db_dbname],
    }
    mysql_grant { "$nova_db_user@%/$nova_db_dbname":
      privileges => 'all',
      provider   => 'mysql',
      require    => Mysql_user["$nova_db_user@%"]
    }

    mysql_database { $cinder_db_dbname:
      ensure => 'present',
      provider => 'mysql',
    }
    mysql_user { "$cinder_db_user@%":
      ensure => 'present',
      password_hash => mysql_password("$cinder_db_password"),
      provider      => 'mysql',
      require => Mysql_database[$cinder_db_dbname],
    }
    mysql_grant { "$cinder_db_user@%/$cinder_db_dbname":
      privileges => 'all',
      provider   => 'mysql',
      require    => Mysql_user["$cinder_db_user@%"]
    }

    mysql_database { $heat_db_dbname:
      ensure => 'present',
      provider => 'mysql',
    }
    mysql_user { "$heat_db_user@%":
      ensure => 'present',
      password_hash => mysql_password("$heat_db_password"),
      provider      => 'mysql',
      require => Mysql_database[$heat_db_dbname],
    }
    mysql_grant { "$heat_db_user@%/$heat_db_dbname":
      privileges => 'all',
      provider   => 'mysql',
      require    => Mysql_user["$heat_db_user@%"]
    }

    if str2bool_i("$neutron") {
      mysql_database { $neutron_db_dbname:
        ensure => 'present',
        provider => 'mysql',
      }
      mysql_user { "$neutron_db_user@%":
        ensure => 'present',
        password_hash => mysql_password("$neutron_db_password"),
        provider      => 'mysql',
        require => Mysql_database[$neutron_db_dbname],
      }
      mysql_grant { "$neutron_db_user@%/$neutron_db_dbname":
        privileges => 'all',
        provider   => 'mysql',
        require    => Mysql_user["$neutron_db_user@%"]
      }
    }
    exec {"pcs-mysql-server-set-up":
      command => "/usr/sbin/pcs property set mysql=running --force",
    }
    Mysql_grant <| |> -> Exec["pcs-mysql-server-set-up"]
  }
}
