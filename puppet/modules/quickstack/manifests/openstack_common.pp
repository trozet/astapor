# Class for nodes running any OpenStack services
class quickstack::openstack_common(
) inherits quickstack::params {

  # openstack-selinux does not exist in el7 yet, but it when it does
  # can just remove the ::operatingsystemrelease clause below
  if (str2bool($::selinux) and $::operatingsystem != "Fedora") {
    if ($::operatingsystemrelease =~ /^6\..*$/)  {
      package{ 'openstack-selinux':
          ensure => present, }
    } else {
      package{ 'selinux-policy':
          ensure => present, }
    }
  }

  # Stop firewalld since everything uses iptables
  # for now (same as packstack did)
  service { "firewalld":
    ensure     => "stopped",
    enable => false,
  }

}
