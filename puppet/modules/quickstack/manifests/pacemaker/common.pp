class quickstack::pacemaker::common (
  $pacemaker_cluster_name    = $quickstack::params::pacemaker_cluster_name,
  $pacemaker_cluster_members = $quickstack::params::pacemaker_cluster_members,
  $pacemaker_disable_stonith = $quickstack::params::pacemaker_disable_stonith,
) inherits quickstack::params {
  class {'pacemaker::corosync':
    cluster_name    => $pacemaker_cluster_name,
    cluster_members => $pacemaker_cluster_members,
  }

  class {'pacemaker::stonith':
    disable => str2bool_i("$pacemaker_disable_stonith"),
  }
}
