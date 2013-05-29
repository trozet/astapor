
# Common trystack configurations
class trystack::compute (
  $fixed_network_range        = $trystack::params::fixed_network_range,
  $floating_network_range     = $trystack::params::floating_network_range,
  $nova_db_password           = $trystack::params::nova_db_password,
  $nova_user_password         = $trystack::params::nova_user_password,
  $pacemaker_priv_floating_ip = $trystack::params::pacemaker_priv_floating_ip,
  $private_interface          = $trystack::params::private_interface,
  $public_interface           = $trystack::params::public_interface,
  $verbose                    = $trystack::params::verbose,
) inherits trystack::params {

    # Configure Nova
    nova_config{
        'auto_assign_floating_ip':  value => 'True';
        #"network_host":            value => ${pacemaker_priv_floating_ip;
        "network_host":             value => "$::ipaddress";
        "libvirt_inject_partition": value => "-1";
        #"metadata_host":           value => "$pacemaker_priv_floating_ip";
        "metadata_host":            value => "$::ipaddress";
        "qpid_hostname":            value => "$pacemaker_priv_floating_ip";
        "rpc_backend":              value => "nova.rpc.impl_qpid";
        "multi_host":               value => "True";
    }

    class { 'nova':
        sql_connection       => "mysql://nova:${nova_db_password}@${pacemaker_priv_floating_ip}/nova",
        image_service        => 'nova.image.glance.GlanceImageService',
        glance_api_servers   => "http://$pacemaker_priv_floating_ip:9292/v1",
        verbose              => $verbose,
    }

    # uncomment if on a vm
    # GSutclif: Maybe wrap this in a Facter['is-virtual'] test ?
    #file { "/usr/bin/qemu-system-x86_64":
    #    ensure => link,
    #    target => "/usr/libexec/qemu-kvm",
    #    notify => Service["nova-compute"],
    #}
    #nova_config{
    #    "libvirt_cpu_mode": value => "none";
    #}

    class { 'nova::compute::libvirt':
        #libvirt_type                => "qemu",  # uncomment if on a vm
        vncserver_listen            => "$::ipaddress",
    }

    class {"nova::compute":
        enabled => true,
        vncproxy_host => "$pacemaker_priv_floating_ip",
        vncserver_proxyclient_address => "$ipaddress",
    }

    class { 'nova::api':
        enabled           => true,
        admin_password    => "$nova_user_password",
        auth_host         => "$pacemaker_priv_floating_ip",
    }

    class { 'nova::network':
        private_interface => "$private_interface",
        public_interface  => "$public_interface",
        fixed_range       => "$fixed_network_range",
        floating_range    => "$floating_network_range",
        network_manager   => "nova.network.manager.FlatDHCPManager",
        config_overrides  => {"force_dhcp_release" => false},
        create_networks   => true,
        enabled           => true,
        install_service   => true,
    }

    firewall { '001 nove compute incoming':
        proto    => 'tcp',
        dport    => '5900-5999',
        action   => 'accept',
    }

}
