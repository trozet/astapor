# Quickstart class for nova network controller
class quickstack::nova_network::controller (
  $auto_assign_floating_ip
) inherits quickstack::params {
  nova_config {
    'DEFAULT/auto_assign_floating_ip': value => $auto_assign_floating_ip;
    'DEFAULT/multi_host':              value => 'True';
    'DEFAULT/force_dhcp_release':      value => 'False';
  }
}
