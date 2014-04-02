class quickstack::pacemaker::rsync::keystone (
  $keystone_private_vip,
  $keystone_group,
) {

  # cwolfe had the idea that perhaps we just need a wait-for-resource-ip (to be
  # running *somewhere*, don't care which node).  add to that
  # "pcs-rsync-server-set-up" should only run if $do_i_match

  $get_resource_ip = "pcs status | grep 'ip-$keystone_private_vip'"
  $which_ip = "$get_resource_ip | sed -n -e 's/^.*Started //p'"
  $do_i_match = "test `$which_ip` == `crm_node -n` >  /dev/null 2>&1"

  $do_i_not_match = "test `$which_ip` != `crm_node -n` > /dev/null 2>&1"
  $get_custom_property = "pcs property show rsync_server"
  $rsync_running = "$get_custom_property | sed -n -e 's/^.*server: //p'"
  $watch_for_server = "test `$rsync_running` == 'running' > /dev/null 2>&1"

  Exec {
    path => '/usr/bin:/usr/sbin:/bin',
  }

  # Check if _this_ is the active node via pcs status exec
  exec {"do-i-match":
    timeout   => 3600,
    tries     => 10,
    try_sleep => 10,
    command   => $do_i_match,
    unless    => $do_i_not_match,
    require   => Class["::quickstack::pacemaker::vip::keystone"],
  }

  class {"rsync::server":
    address    => "$keystone_private_vip",
    use_chroot => 'no',
    require => Exec['do-i-match'],
  }

  rsync::server::module { 'keystone':
    path         => '/etc/keystone/ssl',
    require      => Exec['do-i-match'],
    #hosts_allow => this will become the nodes in the cluster
  }
  # NOTE: we may also want to add a module setting up known hosts, and then we
  # can have client using an ssh key in addition to having to be in the
  # hosts_allow list
  ->
  exec {"pcs-rsync-server-set-up":
    command => "pcs property set rsync_server=running --force",
    #  onlyif  => Exec['do-i-match'],
  }

  # Check if this _isn't_ the active node via pcs status exec
  exec {"do-i-not-match":
    timeout   => 3600,
    tries     => 10,
    try_sleep => 10,
    command   => $do_i_not_match,
    unless    => $do_i_match,
    require   => Class["::quickstack::pacemaker::vip::keystone"],
  }

  exec {"watch-for-server":
    timeout   => 3600,
    tries     => 360,
    try_sleep => 10,
    command   => $watch_for_server,
    unless    => $do_i_match,
    require   => Exec['do-i-match'],
    notify    => Notify['not-a-match'],
  }

  quickstack::pacemaker::rsync::get { '/etc/keystone/ssl':
    source           => "rsync://$keystone_private_vip/keystone/",
    override_options => "aI",
    purge            => true,
    require          => [Exec['do-i-not-match'],Exec['watch-for-server']],
    notify           => Notify['sync-attempted'],
  }
  # these next 3 are just test stuff, remove before commiting

  notify {"not-a-match":
    message => "!!!!!We are not the rsync server, and we know it!",
  }

  notify {"sync-attempted":
    message => "!!!!!We just tried to sync the files!",
  }

}
