class quickstack::firewall::ceilometer (
  $ports = ['8777'],
  $proto = 'tcp',
) {

  include quickstack::firewall::common

  firewall { '001 ceilometer incoming':
    proto  => $proto,
    dport  => $ports,
    action => 'accept',
  }
}
