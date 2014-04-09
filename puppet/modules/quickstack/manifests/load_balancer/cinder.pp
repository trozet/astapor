class quickstack::load_balancer::cinder (
  $frontend_pub_host,
  $frontend_priv_host,
  $frontend_admin_host,
  $backend_server_names,
  $backend_server_addrs,
  $api_port = '8776',
  $api_mode = 'tcp',
) {

  include quickstack::load_balancer::common

  quickstack::load_balancer::proxy { 'cinder-api':
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
}
