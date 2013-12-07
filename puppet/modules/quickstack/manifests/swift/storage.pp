class quickstack::swift::storage (
  # an array
  $all_swift_ips                  = $quickstack::params::all_swift_ips,
  $ext4_device                    = $quickstack::params::swift_ext4_device,
  $loopback                       = $quickstack::params::swift_loopback,
  $ring_server                    = $quickstack::params::swift_proxy_ip,
  $swift_hash_suffix              = $quickstack::params::swift_hash_suffix,
  $swift_local_interface          = $quickstack::params::swift_local_interface,
) inherits quickstack::params {

  class { 'swift::storage::all':
    storage_local_net_ip => getvar("ipaddress_${swift_local_interface}"),
    require => Class['swift'],
  }

  if(!defined(File['/srv/node'])) {
    file { '/srv/node':
      owner  => 'swift',
      group  => 'swift',
      ensure => directory,
      require => Package['openstack-swift'],
    }
  }

  swift::ringsync{["account","container","object"]:
      ring_server => $ring_server,
      before => Class['swift::storage::all'],
      require => Class['swift'],
  }

  File <| |> -> Exec['restorcon']
  exec{'restorcon':
      path => '/sbin:/usr/sbin',
      command => 'restorecon -RvF /srv',
  }

  if ($::selinux != "false"){
      selboolean{'rsync_client':
          value => on,
          persistent => true,
      }
  }

  if str2bool($loopback) {{
    swift::storage::loopback { ['device1']:
      base_dir     => '/srv/loopback-device',
      mnt_base_dir => '/srv/node',
      require      => Class['swift'],
      fstype       => 'ext4',
      seek         => '1048576',
    }
  } else {
    # ########################################################### TODO!
  }

  # Create firewall rules to allow only the hosts that need to connect
  # to swift storage and rsync
  define add_allow_host_swift {
      firewall { "001 swift storage and rsync incoming ${title}":
          proto  => 'tcp',
          dport  => ['6000', '6001', '6002', '873'],
          action => 'accept',
          source => $title,
      }
  }
  add_allow_host_swift {$all_swift_ips:}

  class { 'ssh::server::install': }

  Class['swift'] -> Service <| |>
  class { 'swift':
      # not sure how I want to deal with this shared secret
      swift_hash_suffix => '5f10e7b60b0846f6',
      package_ensure    => latest,
  }

}