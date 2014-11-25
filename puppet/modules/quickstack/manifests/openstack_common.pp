# Class for nodes running any OpenStack services
class quickstack::openstack_common {

  include quickstack::firewall::common
  if (str2bool($::selinux) and $::operatingsystem != "Fedora") {
      package{ 'openstack-selinux':
          ensure => present, }
  }

  service { "auditd":
    ensure => "running",
    enable => true,
  }

  # especially needed for rabbitmq
  sysctl::value { 'net.ipv4.tcp_keepalive_intvl': value => '1' }
  sysctl::value { 'net.ipv4.tcp_keepalive_probes': value => '5' }
  sysctl::value { 'net.ipv4.tcp_keepalive_time': value => '5' }
}
