class quickstack::horizon(
    $bind_address          = '0.0.0.0',
    $cache_server_ip       = '127.0.0.1',
    $cache_server_port     = '11211',
    $fqdn                  = $::fqdn,
    $horizon_cert          = undef,
    $horizon_key           = undef,
    $horizon_ca            = undef,
    $keystone_default_role = 'Member',
    $keystone_host         = '127.0.0.1',
    $listen_ssl            = 'false',
    $memcached_servers     = undef,
    $secret_key,
) {

  include ::memcached

  # horizon packages
  package {'python-memcached':
    ensure => installed,
  }~>
  package {'python-netaddr':
    ensure => installed,
    notify => Class['::horizon'],
  }

  file {'/etc/httpd/conf.d/rootredirect.conf':
    ensure  => present,
    content => 'RedirectMatch ^/$ /dashboard/',
    notify  => File['/etc/httpd/conf.d/openstack-dashboard.conf'],
  }

  class {'::horizon':
    bind_address          => $bind_address,
    cache_server_ip       => $cache_server_ip,
    cache_server_port     => $cache_server_port,
    fqdn                  => $fqdn,
    keystone_default_role => $keystone_default_role,
    keystone_host         => $keystone_host,
    horizon_cert          => $horizon_cert,
    horizon_key           => $horizon_key,
    horizon_ca            => $horizon_ca,
    listen_ssl            => str2bool_i("$ssl"),
    secret_key            => $horizon_secret_key,
  }
  # patch our horizon/apache config to avoid duplicate port 80
  # directive.  TODO: remove this once puppet-horizon/apache can
  # handle it.
  file_line { 'undo_httpd_listen_on_bind_address_80':
    path    => $::horizon::params::httpd_listen_config_file,
    match   => "^.*Listen ${bind_address}:?80$",
    line    => "#Listen ${bind_address}:80",
    require => Package['horizon'],
    notify  => Service[$::horizon::params::http_service],
  }
  File_line['httpd_listen_on_bind_address_80'] -> File_line['undo_httpd_listen_on_bind_address_80']

  file_line { 'ports_listen_on_bind_address_80':
    path    => $::apache::params::ports_file,
    match   => "^.*Listen.*80",
    line    => "Listen ${bind_address}:80",
    require => Package['horizon'],
    notify  => Service[$::horizon::params::http_service],
  }

  Concat::Fragment['Apache ports header'] ->
  File_line['ports_listen_on_bind_address_80']
  # TODO: add a file_line to set array of memcached servers

  if ($::selinux != "false"){
    selboolean { 'httpd_can_network_connect':
      value => on,
      persistent => true,
    }
  }

  class {'::quickstack::firewall::horizon':}
}
