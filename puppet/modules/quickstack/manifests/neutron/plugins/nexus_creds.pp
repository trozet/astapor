define quickstack::neutron::plugins::nexus_creds {
  $args = split($title, '/')
  neutron_plugin_cisco_credentials {
    "${args[0]}/username": value     => $args[1];
    "${args[0]}/password": value => $args[2];
  }
  exec {"${title}":
    unless => "/bin/cat /var/lib/neutron/.ssh/known_hosts
    | /bin/grep ${args[0]}",
    command => "/usr/bin/ssh-keyscan -t rsa ${args[0]}
    >> /var/lib/neutron/.ssh/known_hosts",
    user        => 'neutron',
    require => Package['neutron']
  }
}

