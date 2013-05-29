#!/bin/bash

# PUPPETMASTER is the fqdn that needs to be resolvable by clients.
# Change if needed
if [ "x$PUPPETMASTER" = "x" ]; then
  # Set PuppetServer
  #export PUPPETMASTER=puppet.example.com
  export PUPPETMASTER=$(hostname --fqdn)
fi

if [ "x$SCL_RUBY_HOME" = "x" ]; then
  SCL_RUBY_HOME=/opt/rh/ruby193/root
fi

if [ "x$FOREMAN_INSTALLER_DIR" = "x" ]; then
  FOREMAN_INSTALLER_DIR=/usr/share/openstack-foreman-installer/installer_puppet
fi

if [ "x$FOREMAN_DIR" = "x" ]; then
  FOREMAN_DIR=$SCL_RUBY_HOME/usr/share/foreman
fi

if [ ! -d $FOREMAN_INSTALLER_DIR ]; then
  echo "$FOREMAN_INSTALLER_DIR does not exist.  exiting"
  exit 1
fi

if [ ! -f foreman_server.sh ]; then
  echo "You must be in the same dir as foreman_server.sh when executing it"
  exit 1
fi

if [ ! -f /etc/redhat-release ] || \
    cat /etc/redhat-release | grep -v -q -P 'release 6.[456789]'; then
  echo "This installer is only supported on RHEL 6.4 or greater."
  exit 1
fi

# start with a subscribed RHEL6 box.  hint:
#    subscription-manager register
#    subscription-manager subscribe --auto

# enable ip forwarding
sudo sysctl -w net.ipv4.ip_forward=1
sudo sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf

# disable selinux in /etc/selinux/config
# TODO: selinux policy
setenforce 0

# Puppet configuration
augtool <<EOF
set /augeas/load/Puppet/incl[last()+1] /opt/rh/ruby193/root/etc/puppet/puppet.conf
load
set /files/opt/rh/ruby193/root/etc/puppet/puppet.conf/agent/server $PUPPETMASTER
set /files/opt/rh/ruby193/root/etc/puppet/puppet.conf/main/pluginsync true
save
EOF

pushd $FOREMAN_INSTALLER_DIR
cat > installer.pp << EOM
include puppet
include puppet::server
include passenger
class { 'foreman':
  db_type => 'mysql',
  custom_repo => true,
  app_root => '/opt/rh/ruby193/root/usr/share/foreman'
}
#
# Check foreman_proxy/manifests/{init,params}.pp for other options
class { 'foreman_proxy':
  custom_repo => true,
  dhcp             => true,
  dhcp_gateway     => '10.0.0.1',
  dhcp_range       => '10.0.0.50 10.0.0.200',
  dhcp_nameservers => '10.0.1.2,10.0.1.3',

  dns              => true,
  dns_reverse      => '0.0.10.in-addr.arpa',
}
EOM
scl enable ruby193 "puppet apply --verbose installer.pp --modulepath=. "
popd

########### FIX PASSENGER ################# 
cp ../config/broker-ruby $FOREMAN_DIR
chmod 777 $FOREMAN_DIR/broker-ruby
cp ../config/ruby193-passenger.conf /etc/httpd/conf.d/ruby193-passenger.conf
rm /etc/httpd/conf.d/passenger.conf

### TODO fix foreman db migrate
cp ../config/dbmigrate $FOREMAN_DIR/extras/

# turn on certificate autosigning
echo '*' >> $SCL_RUBY_HOME/etc/puppet/autosign.conf

# Configure class defaults
# This is not ideal, but will work until the API v2 is ready

PASSWD_COUNT=$(cat ../puppet/trystack/manifests/params.pp | grep CHANGEME | wc -l)

for i in $(seq $PASSWD_COUNT)
do
  export PASSWD=$(scl enable ruby193 "ruby foreman-setup.rb password")
  sed -i "/CHANGEME/ {s/CHANGEME/$PASSWD/;:a;n;ba}" ../puppet/trystack/manifests/params.pp
done

# install puppet modules
mkdir -p $SCL_RUBY_HOME/etc/puppet/environments/production/modules
cp -r ../puppet/* $SCL_RUBY_HOME/etc/puppet/environments/production/modules/
sudo -u foreman scl enable ruby193 "cd $FOREMAN_DIR; RAILS_ENV=production rake puppet:import:puppet_classes[batch]"

# reset permissions
sudo -u foreman scl enable ruby193 "cd $FOREMAN_DIR; RAILS_ENV=production rake permissions:reset"

# Configure defaults, host groups, proxy, etc

sed -i "s/foreman_hostname/$PUPPETMASTER/" foreman-params.json

scl enable ruby193 "ruby foreman-setup.rb proxy"
scl enable ruby193 "ruby foreman-setup.rb hostgroups"
# write client-register-to-foreman script
# TODO don't hit yum unless packages are not installed
cat >/tmp/foreman_client.sh <<EOF

# start with a subscribed RHEL6 box
yum install -y augeas ruby193-puppet

# Puppet configuration
augtool <<EOA
set /augeas/load/Puppet/incl[last()+1] /opt/rh/ruby193/root/etc/puppet/puppet.conf
load
set /files/opt/rh/ruby193/root/etc/puppet/puppet.conf/agent/server $PUPPETMASTER
set /files/opt/rh/ruby193/root/etc/puppet/puppet.conf/main/pluginsync true
save
EOA

# check in to foreman
scl enable ruby193 "puppet agent --test"
sleep 1
scl enable ruby193 "puppet agent --test"

/etc/init.d/ruby193-puppet start
EOF

echo "Foreman is installed and almost ready for setting up your OpenStack"
echo "First, you need to alter a few parameters in Foreman."
echo "Visit:"
echo "https://$(hostname)/puppetclasses/trystack::compute/edit"
echo "https://$(hostname)/puppetclasses/trystack::controller/edit"
echo "Go to the Smart Class Parameters tab and work though each of the parameters"
echo "in the left-hand column"
echo ""
echo "Then copy /tmp/foreman_client.sh to your openstack client nodes"
echo "Run that script and visit the HOSTS tab in foreman. Pick CONTROLLER"
echo "host group for your controller node and COMPUTE host group for the rest"
echo ""
echo "Once puppet runs on the machines, OpenStack is ready!"
