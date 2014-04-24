class quickstack::rsync::common ( ) {
  package { 'rsync':
    ensure => installed,
  }
  package { 'xinetd':
    ensure => installed,
  }

  firewall { '010 rsync incoming':
    proto  => 'tcp',
    dport  => ["873"],
    action => 'accept',
  }
}
