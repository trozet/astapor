class quickstack::pacemaker::rsync::galera (
  $db_vip,
) {

  Exec {
    path => '/usr/bin:/usr/sbin:/bin',
  }

  if (($::selinux != "false") and (! defined(Selboolean['rsync_client']))) {
    selboolean { 'rsync_client':
      value      => on,
      persistent => true,
    }
  }

  quickstack::pacemaker::rsync::get { '/etc/pki/galera':
    source           => "rsync://$db_vip/galera/",
    override_options => "aIX",
    purge            => true,
    unless           => "/tmp/ha-all-in-one-util.bash i_am_vip $db_vip",
  }
  ->

  quickstack::rsync::simple { "galera":
    path            => '/etc/pki/galera',
    bind_addr       => "$db_vip",
    max_connections => 10,
  }

  # NOTE: we may also want to add a module setting up known hosts, and then we
  # can have client using an ssh key in addition to having to be in the
  # hosts_allow list

}
