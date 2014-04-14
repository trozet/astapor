class quickstack::rsync::common ( ) {
  package { 'rsync':
    ensure => installed,
  }
  package { 'xinetd':
    ensure => installed,
  }
}
