class passenger::install {
  case $::osfamily {
    RedHat: {
      include passenger::install::redhat
    }
    Debian: {
      include passenger::install::debian
    }
    default: {
      fail("${::hostname}: This module does not support operatingsystem ${::osfamily}")
    }
  }
  file { "${apache::params::configdir}/ruby193-passenger.conf":
    ensure  => $ensure,
    mode    => '0644',
    require => Package['httpd'],
    notify  => Exec['reload-apache'],
    content => template('passenger/ruby193-passenger.conf.erb'),
  }

  file { "${apache::params::configdir}/passenger.conf":
    ensure  => absent,
  }
}
