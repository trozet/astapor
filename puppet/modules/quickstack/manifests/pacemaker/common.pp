# == Class: quickstack::pacemaker::common
#
# A base class to configure your pacemaker cluster
#
# === Parameters
#
# [*pacemaker_cluster_name*]
#   The name of your openstack cluster
# [*pacemaker_cluster_members*]
#   An array of IPs for the nodes in your cluster
# [*fencing_type*]
#   Should be either "disabled", "fence_xvm", "ipmilan", or "". ""
#   means do not disable stonith, but also don't add any fencing
# [*fence_ipmilan_address*]
#
# [*fence_ipmilan_username*]
#
# [*fence_ipmilan_password*]
#
# [*fence_ipmilan_interval*]
#
# [*fence_xvm_clu_iface*]
#
# [*fence_xvm_clu_network*]
#
# [*fence_xvm_manage_key_file*]
#
# [*fence_xvm_key_file_password*]
#

class quickstack::pacemaker::common (
  $pacemaker_cluster_name         = "openstack",
  $pacemaker_cluster_members      = "192.168.200.10 192.168.200.11 192.168.200.12",
  $fencing_type                   = "disabled",
  $fence_ipmilan_address          = "",
  $fence_ipmilan_username         = "",
  $fence_ipmilan_password         = "",
  $fence_ipmilan_interval         = "60s",
  $fence_xvm_clu_iface            = "eth2",
  $fence_xvm_clu_network          = "",
  $fence_xvm_manage_key_file      = "false",
  $fence_xvm_key_file_password    = "",

) {

  include quickstack::pacemaker::params

  class {'pacemaker::corosync':
    cluster_name    => $pacemaker_cluster_name,
    cluster_members => $pacemaker_cluster_members,
  }

  if $fencing_type =~ /(?i-mx:^disabled$)/ {
    class {'pacemaker::stonith':
      disable => true,
    }
    Class['pacemaker::corosync'] -> Class['pacemaker::stonith']
  }
  elsif $fencing_type =~ /(?i-mx:^fence_ipmilan$)/ {
    class {'pacemaker::stonith':
      disable => false,
    }
    class {'pacemaker::stonith::ipmilan':
      address        => $fence_ipmilan_address,
      username       => $fence_ipmilan_username,
      password       => $fence_ipmilan_password,
      interval       => $fence_ipmilan_interval,
      pcmk_host_list => $pacemaker_cluster_members,
    }
    Class['pacemaker::corosync'] -> Class['pacemaker::stonith'] ->
    Class['pacemaker::stonith::ipmilan']
  }
  elsif $fencing_type =~ /(?i-mx:^fence_xvm$)/ {
    $clu_ip_address = find_ip("$fence_xvm_clu_network",
                              "$fence_xvm_clu_iface",
                              "")
    class {'pacemaker::stonith':
      disable => false,
    }
    class {'pacemaker::stonith::fence_xvm':
      name              => "$::hostname",
      manage_key_file   => str2bool_i("$fence_xvm_manage_key_file"),
      key_file_password => $fence_xvm_key_file_password,
      port              => "$::hostname",    # the name of the vm
      pcmk_host         => $clu_ip_address,  # the hostname or IP that pacemaker uses
    }
    Class['pacemaker::corosync'] -> Class['pacemaker::stonith'] ->
    Class['pacemaker::stonith::fence_xvm']
  }

  file { "ha-all-in-one-util-bash-tests":
    path    => "/tmp/ha-all-in-one-util.bash",
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('quickstack/ha-all-in-one-util.erb'),
  }
}
