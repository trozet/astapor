class quickstack::hamysql::node (
  $mysql_root_password         = $quickstack::params::mysql_root_password,
  $keystone_db_password        = $quickstack::params::keystone_db_password,
  $glance_db_password          = $quickstack::params::glance_db_password,
  $nova_db_password            = $quickstack::params::nova_db_password,
  $cinder_db_password          = $quickstack::params::cinder_db_password,
  $heat_db_password            = $quickstack::params::heat_db_password,
  $neutron_db_password         = $quickstack::params::neutron_db_password,
  $neutron                     = $quickstack::params::neutron,

  # these two variables are distinct because you may want to bind on
  # '0.0.0.0' rather than just the floating ip
  $mysql_bind_address           = $quickstack::params::mysql_host,
  $mysql_virtual_ip             = $quickstack::params::mysql_host,
  $mysql_virt_ip_nic            = $quickstack::params::mysql_virt_ip_nic,
  $mysql_virt_ip_cidr_mask      = $quickstack::params::mysql_virt_ip_cidr_mask,
  # e.g. "192.168.200.200:/mnt/mysql"
  $mysql_shared_storage_device  = $quickstack::params::mysql_shared_storage_device,
  # e.g. "nfs"
  $mysql_shared_storage_type    = $quickstack::params::mysql_shared_storage_type,
  #
  $mysql_shared_storage_options = $quickstack::params::mysql_shared_storage_options,
  $mysql_resource_group_name    = $quickstack::params::mysql_resource_group_name,
  $mysql_clu_member_addrs       = $quickstack::params::mysql_clu_member_addrs,

) inherits quickstack::params {

    package { 'mysql-server':
      ensure => installed,
    }
    ->
    package { 'MySQL-python':
      ensure => installed,
    }
    ->
    class {'quickstack::hamysql::mysql::config':
      bind_address =>  $mysql_bind_address,
    }
    ->
    # TODO: use quickstack::pacemaker::common instead
    class {'pacemaker::corosync':
      cluster_name => "hamysql",
      cluster_members => $mysql_clu_member_addrs,
    }
    ->
    # TODO: use quickstack::pacemaker::common instead
    class {"pacemaker::stonith":
      disable => true,
    }
    ->
    pacemaker::resource::ip { 'mysql-clu-vip' :
      ip_address => $mysql_virtual_ip,
      group => $mysql_resource_group_name,
      cidr_netmask => $mysql_virt_ip_cidr_mask,
      nic => $mysql_virt_ip_nic,
    }
    ->
    pacemaker::resource::filesystem { 'mysql-clu-fs' :
       device => "$mysql_shared_storage_device",
       directory => "/var/lib/mysql",
       fstype => $mysql_shared_storage_type,
       fsoptions => $mysql_shared_storage_options,
       group => $mysql_resource_group_name,
    }
    ->
    exec { "let-mysql-fs-get-mounted":
      command => "/bin/sleep 15"
    }
    ->
    pacemaker::resource::mysql { 'mysql-clu-mysql' :
      name => "ostk-mysql",
      group => $mysql_resource_group_name,
    }
    ->
    pacemaker::constraint::base { 'ip-mysql-constr' :
      constraint_type => "order",
      first_resource  => "ip-${mysql_virtual_ip}",
      second_resource => "mysql-ostk-mysql",
      first_action    => "start",
      second_action   => "start",
    }
    ->
    pacemaker::constraint::base { 'fs-mysql-constr' :
      constraint_type => "order",
      first_resource  => "fs-varlibmysql",
      second_resource => "mysql-ostk-mysql",
      first_action    => "start",
      second_action   => "start",
    }
    ->
    exec {"wait-for-mysql-to-start":
      timeout => 3600,
      tries => 360,
      try_sleep => 10,
      command => "/usr/sbin/pcs status  | grep -q 'mysql-ostk-mysql.*Started' > /dev/null 2>&1",
    }

    class {'quickstack::hamysql::mysql::rootpw':
      require => File['are-we-running-mysql-script'],
      root_password => $mysql_root_password,
    }

   file {"are-we-running-mysql-script":
     name => "/tmp/are-we-running-mysql.bash",
     ensure => present,
     owner => root,
     group => root,
     mode  => 777,
     content => "#!/bin/bash\n a=`/usr/sbin/pcs status | grep -P 'mysql-ostk-mysql\\s.*Started' | perl -p -e 's/^.*Started (\S*).*$/\$1/'`; b=`/usr/sbin/crm_node -n`; echo \$a; echo \$b; \ntest \$a = \$b;\n",
     require => Exec['wait-for-mysql-to-start'],
    }

    class {'quickstack::hamysql::mysql::setup':
      keystone_db_password => $keystone_db_password,
      glance_db_password   => $glance_db_password,
      nova_db_password     => $nova_db_password,
      cinder_db_password   => $cinder_db_password,
      heat_db_password     => $heat_db_password,
      neutron_db_password  => $neutron_db_password,
      neutron              => str2bool_i("$neutron"),
      require              => Class['quickstack::hamysql::mysql::rootpw'],
    }

    firewall { '002 mysql incoming':
      proto => 'tcp',
      dport => ['3306'],
      action => 'accept',
    }
}
