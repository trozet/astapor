#!/bin/bash

# PUPPETMASTER is the fqdn that needs to be resolvable by clients.
# Change if needed
if [ "x$PUPPETMASTER" = "x" ]; then
  # Set PuppetServer
  #export PUPPETMASTER=puppet.example.com
  export PUPPETMASTER=$(hostname --fqdn)
fi

if `echo $PUPPETMASTER | grep -v -q '\.'`; then
  echo "PUPPETMASTER has a value of $PUPPETMASTER but it must be a fqdn"
  exit 1
fi

# FOREMAN_PROVISIONING determines whether configure foreman for bare
# metal provisioning including installing dns and dhcp servers.
if [ "x$FOREMAN_PROVISIONING" = "x" ]; then
  FOREMAN_PROVISIONING=true
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

if [ "$FOREMAN_PROVISIONING" = "true" ]; then
  NUM_INT=$(scl enable ruby193 "facter -p"|grep ipaddress_|grep -v _lo|wc -l)          
  if [[ $NUM_INT -lt 2 ]] ; then                                                       
    echo "This installer needs 2 configured interfaces - only $NUM_INT detected"    
    exit 1                                                                             
  fi                                                                                   
  PRIMARY_INT=$(route|grep default|awk ' { print ( $(NF) ) }')                         
  SECONDARY_INT=$(scl enable ruby193 "facter -p"|grep ipaddress_|grep -Ev "_lo|$PRIMARY_INT"|awk -F"[_ ]" '{print $2;exit 0}')
  SECONDARY_PREFIX=$(scl enable ruby193 "facter network_${SECONDARY_INT}" | cut -d. -f1-3) # -> 10.0.0 -> '0.0.10.in-addr.arpa',
  SECONDARY_REVERSE=$(echo "$SECONDARY_PREFIX" | ( IFS='.' read a b c ; echo "$c.$b.$a.in-addr.arpa" ))
  FORWARDER=$(augtool get /files/etc/resolv.conf/nameserver[1] | awk '{printf $NF}')
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

# fix db migrate script for scl
cp ../config/dbmigrate $FOREMAN_DIR/extras/
# fix broken passenger config file for scl
cp ../config/broker-ruby $FOREMAN_DIR
chmod 775 $FOREMAN_DIR/broker-ruby

pushd $FOREMAN_INSTALLER_DIR
cat > installer.pp << EOM
class { 'puppet':
  runmode => 'cron',
}
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
EOM

if [ "$FOREMAN_PROVISIONING" = "true" ]; then
cat >> installer.pp << EOM
  dhcp             => true,
  dhcp_gateway     => '${SECONDARY_PREFIX}.1',
  dhcp_range       => '${SECONDARY_PREFIX}.50 ${SECONDARY_PREFIX}.200',
  dhcp_interface   => '${SECONDARY_INT}',

  dns              => true,
  dns_reverse      => '${SECONDARY_REVERSE}',
  dns_forwarders   => ['${FORWARDER}'],
  dns_interface    => '${SECONDARY_INT}',
}
EOM

else
cat >> installer.pp << EOM
  dhcp             => false,
  dns              => false,
  tftp             => false,
}
EOM
  
fi

scl enable ruby193 "puppet apply --verbose installer.pp --modulepath=. "
popd

# reset permissions
sudo -u foreman scl enable ruby193 "cd $FOREMAN_DIR; RAILS_ENV=production rake permissions:reset"

# turn on certificate autosigning
echo '*' >> $SCL_RUBY_HOME/etc/puppet/autosign.conf

sed -i "s/foreman_hostname/$PUPPETMASTER/" foreman-params.json

# Add smart proxy
scl enable ruby193 "ruby foreman-setup.rb proxy"

# Configure class defaults
# This is not ideal, but will work until the API v2 is ready

PASSWD_COUNT=$(cat ../puppet/modules/trystack/manifests/params.pp | grep CHANGEME | wc -l)

for i in $(seq $PASSWD_COUNT)
do
  export PASSWD=$(scl enable ruby193 "ruby foreman-setup.rb password")
  sed -i "/CHANGEME/ {s/CHANGEME/$PASSWD/;:a;n;ba}" ../puppet/modules/trystack/manifests/params.pp
done

sed -i "s/PRIMARY/$PRIMARY_INT/" ../puppet/modules/trystack/manifests/params.pp
sed -i "s/SECONDARY/$SECONDARY_INT/" ../puppet/modules/trystack/manifests/params.pp

# install puppet modules
mkdir -p $SCL_RUBY_HOME/etc/puppet/environments/production/modules
cp -r ../puppet/modules/* $SCL_RUBY_HOME/etc/puppet/environments/production/modules/
sudo -u foreman scl enable ruby193 "cd $FOREMAN_DIR; RAILS_ENV=production rake puppet:import:puppet_classes[batch]"

# Configure defaults, host groups, proxy, etc
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
