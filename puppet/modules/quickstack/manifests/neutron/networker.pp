
class quickstack::neutron::networker (
  $fixed_network_range          = $quickstack::params::fixed_network_range,
  $floating_network_range       = $quickstack::params::floating_network_range,
  $metadata_proxy_shared_secret = $quickstack::params::metadata_proxy_shared_secret,
  $neutron_db_password          = $quickstack::params::neutron_db_password,
  $nova_db_password             = $quickstack::params::nova_db_password,
  $nova_user_password           = $quickstack::params::nova_user_password,
  $private_ip                   = $quickstack::params::private_ip,
  $controller_priv_floating_ip  = $quickstack::params::controller_priv_floating_ip,
  $private_interface            = $quickstack::params::private_interface,
  $public_interface             = $quickstack::params::public_interface,
  $verbose                      = $quickstack::params::verbose,
) inherits quickstack::params {

    class { '::neutron':
        verbose               => true,
        allow_overlapping_ips => true,
        rpc_backend           => 'neutron.openstack.common.rpc.impl_qpid',
        qpid_hostname         => $controller_priv_floating_ip,
    }
    
    neutron_config {
        'database/connection': value => "mysql://neutron:${neutron_db_password}@${controller_priv_floating_ip}/neutron";

        'keystone_authtoken/admin_tenant_name': value => 'admin';
        'keystone_authtoken/admin_user':        value => 'admin';
        'keystone_authtoken/admin_password':    value => $admin_password;
        'keystone_authtoken/auth_host':         value => $controller_priv_floating_ip;
    }

    class { '::neutron::plugins::ovs':
        sql_connection      => "mysql://neutron:${neutron_db_password}@${controller_priv_floating_ip}/neutron",
        tenant_network_type => 'gre',
    }

    class { '::neutron::agents::ovs':
        local_ip         => $private_ip,
        enable_tunneling => true,
    }

    class { '::neutron::agents::dhcp': }

    class { '::neutron::agents::l3': }

    class { 'neutron::agents::metadata':
        auth_password => $admin_password,
        shared_secret => $metadata_proxy_shared_secret,
        auth_url      => "http://${controller_priv_floating_ip}:35357/v2.0",
        metadata_ip   => $controller_priv_floating_ip,
    }

    #class { 'neutron::agents::lbaas': }

    #class { 'neutron::agents::fwaas': }

    # Neutron external network for br-ex
    #keystone_tenant { 'admin':
    #    ensure => present,
    #}

    #neutron_network { 'public':
    #    ensure          => present,
    #    router_external => 'True',
    #    tenant_name     => 'admin',

    #neutron_subnet { 'public_subnet':
    #    ensure           => 'present',
    #    cidr             => '10.16.16.0/22',
    #    gateway_ip       => '10.16.19.254',
    #    allocation_pools => 'start=10.16.18.1,end=10.16.18.254',
    #    network_name     => 'public',
    #    tenant_name      => 'admin',
    #}
}
