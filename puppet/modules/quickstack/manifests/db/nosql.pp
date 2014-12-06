# == Class: quickstack::db::nosql
#
# Install a nosql server (MongoDB)
#
# === Parameters:
#
# [*bind_host*]
#   (optional) IP address on which mongod instance should listen
#   Defaults to '127.0.0.1'
#
# [*nojournal*]
#   (optional) Disable mongodb internal cache. This is not recommended for
#   production but results in a much faster boot process.
#   http://docs.mongodb.org/manual/reference/configuration-options/#nojournal
#   Defaults to false
#
# [*port*]
#   (optional) Port on which mongod instance should listen
#   Defaults to '27017'
#
# [*service_enable*]
#   (optional) Whether to enable the system unit for mongo server
#   Defaults to true
#
# [*service_ensure*]
#   (optional) Whether to start or stop the mongo server. Set to undef
#   to tell puppet not to manage the service status.
#   Defaults to 'running'


class quickstack::db::nosql(
  $bind_host             = '127.0.0.1',
  $nojournal             = false,
  $port                  = '27017',
  $service_enable        = true,
  $service_ensure        = 'running',
  $service_start_timeout = '240',
) {

  # This can be removed when bz 1040573 is resolved
  # https://bugzilla.redhat.com/show_bug.cgi?id=1040573
  if (($::operatingsystem == 'fedora' and versioncmp($::operatingsystemrelease, '22') >= 0) or
      ($::operatingsystem != 'fedora' and versioncmp($::operatingsystemrelease, '7.0') >= 0)) {
    $mongodb_service_file_path = '/usr/lib/systemd/system/mongod.service'
  } else {
    $mongodb_service_file_path = '/usr/lib/systemd/system/mongodb.service'
  }
  file_line {'mongodb start timeout':
    path => $mongodb_service_file_path,
    after => '\[Service\]',
    line => "TimeoutStartSec=$service_start_timeout",
  } -> Service['mongodb']

  anchor {'mongodb setup start': }
  ->
  class { '::mongodb::globals':
    service_enable => $service_enable,
    service_ensure => $service_ensure,
  }
  ->
  class {'mongodb::client':}
  ->
  class { '::mongodb':
    bind_ip   => [$bind_host,'127.0.0.1'],
    nojournal => $nojournal,
    port      => $port,
    replset   => 'ceilometer',
  }
  ->
  exec {'check_mongodb' :
    command   => "/usr/bin/mongo ${bind_host}:27017",
    logoutput => false,
    tries     => 60,
    try_sleep => 5,
    require   => Service['mongodb'],
  }

  anchor {'mongodb setup done' :
    require => Exec['check_mongodb'],
  }

  Anchor['mongodb setup start'] -> Service[mongodb] -> Anchor['mongodb setup done']
}
