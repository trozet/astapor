class quickstack::load_balancer::common {

  class { 'haproxy':
    global_options => {
      'log'        => '/dev/log local0',
      'pidfile'    => '/var/run/haproxy.pid',
      'user'       => 'haproxy',
      'group'      => 'haproxy',
      'daemon'     => '',
      'maxconn'    => '4000',
    },
    defaults_options => {
      'mode'         => 'http',
      'log'          => 'global',
      'retries'      => '3',
      'option'       => [ 'httplog', 'redispatch' ],
      'timeout'      => [ 'connect 10s', 'client 1m', 'server 1m' ],
    },
  }

  haproxy::listen { 'stats':
    ipaddress => '*',
    ports     => '81',
    mode      => 'http',
    options   => {
      'stats' => 'enable',
    },
    collect_exported => false,
  }

  sysctl::value { 'net.ipv4.ip_nonlocal_bind': value => '1' }
}
