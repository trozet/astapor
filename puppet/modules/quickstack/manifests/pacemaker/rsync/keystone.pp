class quickstack::pacemaker::rsync::keystone (
  $keystone_private_vip,
  $keystone_group,
) {

  Exec {
    path => '/usr/bin:/usr/sbin:/bin',
  }

  class {"rsync::server":
    address    => "$keystone_private_vip",
    use_chroot => 'no',
  }

  rsync::server::module { 'keystone':
    path         => '/etc/keystone/ssl',
    #hosts_allow => this will become the nodes in the cluster
  }
  # NOTE: we may also want to add a module setting up known hosts, and then we
  # can have client using an ssh key in addition to having to be in the
  # hosts_allow list

  #->
  #exec {"pcs-rsync-server-set-up":
  #  command => "pcs property set rsync_server=running --force",
  #  #  onlyif  => Exec['do-i-match'],
  #}

  # now using pcs property "keystone" instead of "rsync_server"
  # (commented out above) as the waiting condition -- this logic now
  # lives in pacemaker::keystone.  If we get to this module and
  # execute below, it means that either we are the keystone vip, or
  # we know the keystone vip is already set up with rsync server
  quickstack::pacemaker::rsync::get { '/etc/keystone/ssl':
    source           => "rsync://$keystone_private_vip/keystone/",
    override_options => "aI",
    purge            => true,
  }

}
