class quickstack::cinder_volume(
  $backend_glusterfs      = false,
  $backend_glusterfs_name = 'glusterfs_backend',
  $backend_iscsi          = false,
  $backend_iscsi_name     = 'iscsi_backend',
  $backend_nfs            = false,
  $backend_nfs_name       = 'nfs_backend',

  $multiple_backends      = false,

  $iscsi_bind_addr        = '',

  $glusterfs_shares       = [],

  $nfs_shares             = [],
  $nfs_mount_options      = undef,
) {
  class { '::cinder::volume': }

  if !str2bool_i("$multiple_backends") {
    # single backend

    if str2bool_i("$backend_glusterfs") {
      if defined('gluster::client') {
        class { 'gluster::client': }
        ->
        Class['::cinder::volume']
      } else {
        class { 'puppet::vardir': }
        ->
        class { 'gluster::mount::base': repo => false }
        ->
        Class['::cinder::volume']
      }

      if ($::selinux != "false") {
        selboolean { 'virt_use_fusefs':
            value => on,
            persistent => true,
        }
      }

      class { '::cinder::volume::glusterfs':
        glusterfs_mount_point_base => '/var/lib/cinder/volumes',
        glusterfs_shares           => $glusterfs_shares,
        glusterfs_shares_config    => '/etc/cinder/shares-glusterfs.conf',
      }
    } elsif str2bool_i("$backend_nfs") {
      if ($::selinux != "false") {
        selboolean { 'virt_use_nfs':
            value => on,
            persistent => true,
        }
      }

      class { '::cinder::volume::nfs':
        nfs_servers       => $nfs_shares,
        nfs_mount_options => $nfs_mount_options,
        nfs_shares_config => '/etc/cinder/shares-nfs.conf',
      }
    } elsif str2bool_i("$backend_iscsi") {
      include ::quickstack::firewall::iscsi

      class { '::cinder::volume::iscsi':
        iscsi_ip_address => $iscsi_bind_addr,
      }
    } else {
      fail("Enable a backend for cinder-volume.")
    }

  } else {
    # multiple backends

    if str2bool_i("$backend_glusterfs") {
      $glusterfs_backends = ["glusterfs"]

      if defined('gluster::client') {
        class { 'gluster::client': }
        ->
        Class['::cinder::volume']
      } else {
        class { 'puppet::vardir': }
        ->
        class { 'gluster::mount::base': repo => false }
        ->
        Class['::cinder::volume']
      }

      if ($::selinux != "false") {
        selboolean { 'virt_use_fusefs':
            value => on,
            persistent => true,
        }
      }

      cinder::backend::glusterfs { 'glusterfs':
        volume_backend_name        => $backend_glusterfs_name,
        glusterfs_mount_point_base => '/var/lib/cinder/volumes',
        glusterfs_shares           => $glusterfs_shares,
        glusterfs_shares_config    => '/etc/cinder/shares-glusterfs.conf',
      }
    }

    if str2bool_i("$backend_nfs") {
      $nfs_backends = ["nfs"]

      if ($::selinux != "false") {
        selboolean { 'virt_use_nfs':
            value => on,
            persistent => true,
        }
      }

      cinder::backend::nfs { 'nfs':
        volume_backend_name => $backend_nfs_name,
        nfs_servers         => $nfs_shares,
        nfs_mount_options   => $nfs_mount_options,
        nfs_shares_config   => '/etc/cinder/shares-nfs.conf',
      }
    }

    if str2bool_i("$backend_iscsi") {
      $iscsi_backends = ["iscsi"]

      include ::quickstack::firewall::iscsi

      cinder::backend::iscsi { 'iscsi':
        volume_backend_name => $backend_iscsi_name,
        iscsi_ip_address    => $iscsi_bind_addr,
      }
    }

    $enabled_backends = join_arrays_if_exist(
      'glusterfs_backends',
      'nfs_backends',
      'iscsi_backends')
    if $enabled_backends == [] {
      fail("Enable at least one backend for cinder-volume.")
    }

    # enable the backends
    class { 'cinder::backends':
      enabled_backends => $enabled_backends,
    }
  }
}
