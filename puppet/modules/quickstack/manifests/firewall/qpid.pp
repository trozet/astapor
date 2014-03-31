class quickstack::firewall::qpid {

  include quickstack::firewall::common

  firewall { '001 qpid incoming':
    proto  => 'tcp',
    dport  => ['5672'],
    action => 'accept',
  }
}
