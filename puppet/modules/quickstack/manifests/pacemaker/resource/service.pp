define quickstack::pacemaker::resource::service($group='',
                                                $clone=false,
                                                $interval='30s',
                                                $ensure='present') {
  include quickstack::pacemaker::params

  if has_interface_with("ipaddress", map_params("cluster_control_ip")){
    ::pacemaker::resource::service{ "$name":
                                group    => $group,
                                clone    => $clone,
                                interval => $interval,
                                ensure   => $ensure}
  }
}
