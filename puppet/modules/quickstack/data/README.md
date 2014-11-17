# Hiera built in data

## Setup
* Install Puppet and Git RPMs
`yum install -y puppet git`

* Install openstack-puppet-modules RPM
`yum -y install openstack-puppet-modules`

* Install Quickstack module
  - Use Astapor fork: https://github.com/gildub/astapor/tree/HA+Hiera
  or
  - Install OFI RPM and add Astapor/PR#391 patch

* Create following link for Hiera to work with Puppet (BZ#1108039) :
`ln -sf /etc/hiera.yaml /etc/puppet/hiera.yaml`

* Copy classes file as global hiera default file
```cp /usr/share/openstack-foreman-installer/puppet/modules/quickstack/data/classes.yaml /var/lib/hiera/defaults.yaml```

## Masterless Deployment - No Puppet master or neither Foreman server needed
* Change values in YAML files accordingly

* Run Puppet on each node

```puppet apply -e "hiera_include(<NODE_TYPE>)" \ --modulepath=/usr/share/openstack-puppet/modules:/usr/share/openstack-foreman-installer/puppet/modules```

where

  ```<NODE_TYPE> ::= HA_AIO_classes | compute_classes```

## Notes
* Tested on RHO5/RHEL7
* Setenforce 0 - Nova scheduler: missing SELinux AVC => BZ#1149975
* Latest Puppet module concat needed (already available in OPM Icehouse and Master branches)
* The Openstack Puppet Modules include module-data needed for module built-in YAML data
