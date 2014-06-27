class quickstack::load_balancer::amqp (
  $frontend_host        = '',
  $backend_server_names = [],
  $backend_server_addrs = [],
  $port                 = '5672',
  $backend_port         = '15672',
  $mode                 = 'tcp',
  $timeout              = '120s',
  $log                  = 'tcplog',
) {

  include quickstack::load_balancer::common

  quickstack::load_balancer::proxy { 'amqp':
    addr                 => "$frontend_host",
    port                 => "$port",
    mode                 => "$mode",
    listen_options       => { 'option' => [ "$log" ],
                              'timeout' => [ "client $timeout",
                                             "server $timeout", ],
                              'stick-table' => 'type ip size 2',
                              'stick' => 'on dst', },
    member_options       => [ 'check' ],
    backend_server_addrs => $backend_server_addrs,
    backend_server_names => $backend_server_names,
    backend_port         => $backend_port,
  }
}
