# == Class: quickstack::pacemaker::hosts
#
# This exists so that pacemaker can have hostnames for its ip's

define quickstack::pacemaker::hosts (
  $index            = 0,
  $ip_address_array = [],
  $hostname_array   = [],
) {

  if($index >= 0)
  {
    $hostname = $hostname_array[$index]
    $ip_address= $ip_address_array[$index]

    host { "$hostname":
      ip => $ip_address,
    }

    #recurse
    $next = $index -1
    quickstack::pacemaker::hosts {$next:
      index            => $next,
      ip_address_array => $ip_address_array,
      hostname_array   => $hostname_array
    }
  }
}
