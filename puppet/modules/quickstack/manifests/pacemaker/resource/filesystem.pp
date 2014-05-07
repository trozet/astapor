define quickstack::pacemaker::resource::filesystem($device,
                                       $directory,
                                       $fsoptions='',
                                       $fstype,
                                       $group='',
                                       $clone=false,
                                       $interval='30s',
                                       $ensure='present') {
  include quickstack::pacemaker::params

  if has_interface_with("ipaddress", map_params("cluster_control_ip")){  
    ::pacemaker::resource::filesystem{ "$name":
                                       device    => $device,
                                       directory => $directory,
                                       fsoptions => $fsoptions,
                                       fstype    => $fstype,
                                       group     => $group,
                                       clone     => $clone,
                                       interval  => $interval,
                                       ensure    => $ensure}
  }
}
