class quickstack::firewall::qpid(
  $ports = ['5672'],
) {

  include quickstack::firewall::common

  firewall { '001 qpid incoming':
    proto  => 'tcp',
    dport  => $ports,
    action => 'accept',
  }
}
