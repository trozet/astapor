class quickstack::cinder_volume(
  $volume_backend,
  $iscsi_bind_addr  = '',
  $glusterfs_shares = [],
) {
  class { '::cinder::volume': }

  if $volume_backend == 'glusterfs' {
    if defined('gluster::client') {
      class { 'gluster::client': }
      ->
      Class['::cinder::volume']
    } else {
      class { 'gluster::mount::base': repo => false }
      ->
      Class['::cinder::volume']
    }

    if ($::selinux != "false") {
      selboolean {'virt_use_fusefs':
          value => on,
          persistent => true,
      }
    }

    class { '::cinder::volume::glusterfs':
      glusterfs_mount_point_base => '/var/lib/cinder/volumes',
      glusterfs_shares => $glusterfs_shares,
    }
  } elsif $volume_backend == 'iscsi' {
    include ::quickstack::firewall::iscsi

    class { '::cinder::volume::iscsi':
      iscsi_ip_address => $iscsi_bind_addr,
    }
  } else {
      fail("Unsupported cinder volume backend '${volume_backend}'")
  }
}
