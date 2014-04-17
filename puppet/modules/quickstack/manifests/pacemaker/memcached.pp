class quickstack::pacemaker::memcached {

  include ::memcached

  Class['::memcached'] ->
  Class['::quickstack::pacemaker::common'] ->
  pacemaker::resource::lsb { 'memcached':
    group   => 'openstack_memcached',
    clone   => true,
  }

}
