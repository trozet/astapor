# Class for nodes running any OpenStack services
class quickstack::openstack_common(
) inherits quickstack::params {

  if str2bool($::selinux) and $::operatingsystem != "Fedora" {
    package{ 'openstack-selinux':
        ensure => present,
    }
  }

}
