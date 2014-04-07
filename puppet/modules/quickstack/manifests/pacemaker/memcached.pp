class quickstack::pacemaker::memcached {

  class {'::memcached':}
  ->
  pacemaker::resource::lsb { 'memcached':
    group   => 'openstack_memcached',
    clone   => true,
  }

  Class['::memcached'] ->
  Class['::quickstack::pacemaker::common'] ->
  Class['::quickstack::pacemaker::memcached']
}
