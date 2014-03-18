class quickstack::load_balancer::glance (
  $frontend_pub_host,
  $frontend_priv_host,
  $frontend_admin_host,
  $backend_server_names,
  $backend_server_addrs,
  $api_port = '9191',
  $api_mode = 'tcp',
  $registry_port = '9292',
  $registry_mode = 'tcp',
) {

  include quickstack::load_balancer::common

  quickstack::load_balancer::proxy { 'glance-api':
    addr                 => [ $frontend_pub_host,
                              $frontend_priv_host,
                              $frontend_admin_host ],
    port                 => "$api_port",
    mode                 => "$api_mode",
    listen_options       => { 'option' => [ 'httplog' ] },
    member_options       => [ 'check' ],
    backend_server_addrs => $backend_server_addrs,
    backend_server_names => $backend_server_names,
  }

  quickstack::load_balancer::proxy { 'glance-registry':
    addr                 => [ $frontend_pub_host,
                              $frontend_priv_host,
                              $frontend_admin_host ],
    port                 => "$registry_port",
    mode                 => "$registry_mode",
    listen_options       => { 'option' => [ 'httplog' ] },
    member_options       => [ 'check' ],
    backend_server_addrs => $backend_server_addrs,
    backend_server_names => $backend_server_names,
  }
}
