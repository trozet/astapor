class quickstack::swift::proxy (
  $controller_pub_host,
  $swift_admin_password,
  $swift_shared_secret,
) inherits quickstack::params {

    #### Swift ####
    package { 'curl': ensure => present }

    class { '::swift::proxy':
      proxy_local_net_ip => $controller_pub_host,
      pipeline           => [
        'healthcheck',
        'cache',
        'authtoken',
        'keystone',
        'proxy-server'
      ],
      account_autocreate => true,
    }

    # configure all of the middlewares
    class { [
        '::swift::proxy::catch_errors',
        '::swift::proxy::healthcheck',
        '::swift::proxy::cache',
    ]: }

    class { '::swift::proxy::ratelimit':
        clock_accuracy         => 1000,
        max_sleep_time_seconds => 60,
        log_sleep_time_seconds => 0,
        rate_buffer_seconds    => 5,
        account_ratelimit      => 0
    }

    class { '::swift::proxy::keystone':
        operator_roles => ['admin', 'SwiftOperator'],
    }

    class { '::swift::proxy::authtoken':
        admin_user        => 'swift',
        admin_tenant_name => 'services',
        admin_password    => $swift_admin_password,
        # assume that the controller host is the swift api server
        auth_host         => $controller_pub_host,
    }

    class {'quickstack::swift::common':
      swift_shared_secret => $swift_shared_secret,
    }

    firewall { '001 swift proxy incoming':
        proto    => 'tcp',
        dport    => ['8080'],
        action   => 'accept',
    }

    swift::ringsync{["account","container","object"]:
        ring_server => $controller_pub_host,
    }

    class { '::swift::ringbuilder':
        part_power     => '18',
        replicas       => '1',
        min_part_hours => 1,
        require        => Class['swift'],
    }

    # sets up an rsync db that can be used to sync the ring DB
    class { '::swift::ringserver':
        local_net_ip => $controller_pub_host,
    }

}
