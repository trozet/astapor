class quickstack::firewall::nosql(
  $ports = ['27017'],
) {

  include quickstack::firewall::common

  firewall { '001 nosql incoming':
    proto  => 'tcp',
    dport  => $ports,
    action => 'accept',
  }
}
