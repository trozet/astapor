define quickstack::pacemaker::resource::galera($timeout     = '300s',
                                               $gcomm_addrs = [] ) {
  include quickstack::pacemaker::params

  if has_interface_with("ipaddress", map_params("cluster_control_ip")){

    $num_nodes = size($gcomm_addrs)
    $gcomm_addresses = inline_template('gcomm://<%= @gcomm_addrs.join "," %>')
    $create_cmd = "/usr/sbin/pcs resource create galera galera enable_creation=true wsrep_cluster_address=\"$gcomm_addresses\" meta master-max=$num_nodes ordered=true op promote timeout=$timeout on-fail=block --master"

    anchor { "qprs start galera": }
    ->
    # probably want to move this to puppet-pacemaker eventually
    exec {"create galera resource":
      command => $create_cmd,
      unless => '/usr/sbin/pcs resource show galera'
    }
    ->
    exec {"wait for galera resource":
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      command   => "/usr/sbin/pcs resource show galera",
    }
    -> anchor { "qprs end galera": }
  }
}
