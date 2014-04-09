class quickstack::cinder_volume(
  $volume_backend    = 'iscsi',
  $iscsi_bind_addr   = undef,
  $gluster_volume    = undef,
  $gluster_servers   = undef,
) {
  class { '::cinder::volume': }

  if $volume_backend == 'iscsi' {
    include ::quickstack::firewall::iscsi

    class { '::cinder::volume::iscsi':
      iscsi_ip_address => $iscsi_bind_addr,
    }
  } else {
      fail("Unsupported cinder volume backend '${volume_backend}'")
  }
}
