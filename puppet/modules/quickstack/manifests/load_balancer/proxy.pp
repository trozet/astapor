define quickstack::load_balancer::proxy (
  $addr,
  $port,
  $mode,
  $listen_options,
  $member_options,
  $define_cookies = false,
  $backend_server_names,
  $backend_server_addrs,
) {

  haproxy::listen { $name:
    ipaddress        => $addr,
    ports            => $port,
    mode             => $mode,
    options          => $listen_options,
    collect_exported => false,
  }

  haproxy::balancermember { $name:
    listening_service => $name,
    ports             => $port,
    server_names      => $backend_server_names,
    ipaddresses       => $backend_server_addrs,
    options           => $member_options,
    define_cookies    => $define_cookies,
  }
}
