class quickstack::galera::db (
  $keystone_db_user       = 'keystone',
  $keystone_db_dbname     = 'keystone',
  $keystone_db_password,
  $glance_db_user         = 'glance',
  $glance_db_dbname       = 'glance',
  $glance_db_password,
  $nova_db_user           = 'nova',
  $nova_db_dbname         = 'nova',
  $nova_db_password,
  $heat_db_user           = 'heat',
  $heat_db_dbname         = 'heat',
  $heat_db_password,
  $cinder_db_user         = 'cinder',
  $cinder_db_dbname       = 'cinder',
  $cinder_db_password,
  $neutron_db_user        = 'neutron',
  $neutron_db_dbname      = 'neutron',
  $neutron_db_password,
) {

  mysql_database { $keystone_db_dbname:
    ensure   => 'present',
    provider => 'mysql',
  }
  mysql_user { "$keystone_db_user@%":
    ensure => 'present',
    password_hash => mysql_password("$keystone_db_password"),
    provider      => 'mysql',
    require => Mysql_database[$keystone_db_dbname],
  }
  mysql_grant { "$keystone_db_user@%/$keystone_db_dbname.*":
    privileges => 'all',
    provider   => 'mysql',
    user       => "$keystone_db_user@%",
    table      => "$keystone_db_dbname.*",
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
  mysql_grant { "$glance_db_user@%/$glance_db_dbname.*":
    privileges => 'all',
    provider   => 'mysql',
    user       => "$glance_db_user@%",
    table      => "$glance_db_dbname.*",
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
  mysql_grant { "$nova_db_user@%/$nova_db_dbname.*":
    privileges => 'all',
    provider   => 'mysql',
    user       => "$nova_db_user@%",
    table      => "$nova_db_dbname.*",
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
  mysql_grant { "$cinder_db_user@%/$cinder_db_dbname.*":
    privileges => 'all',
    provider   => 'mysql',
    user       => "$cinder_db_user@%",
    table      => "$cinder_db_dbname.*",
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
  mysql_grant { "$heat_db_user@%/$heat_db_dbname.*":
    privileges => 'all',
    provider   => 'mysql',
    user       => "$heat_db_user@%",
    table      => "$heat_db_dbname.*",
    require    => Mysql_user["$heat_db_user@%"]
  }

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
  mysql_grant { "$neutron_db_user@%/$neutron_db_dbname.*":
    privileges => 'all',
    provider   => 'mysql',
    user       => "$neutron_db_user@%",
    table      => "$neutron_db_dbname.*",
    require    => Mysql_user["$neutron_db_user@%"]
  }
}
