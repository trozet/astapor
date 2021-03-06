#!/bin/bash

echo "#################### RED HAT OPENSTACK #####################"
echo "Thank you for using the Red Hat OpenStack Foreman Installer!"
echo "############################################################"

read -p "Press [Enter] to continue"

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

# FOREMAN_GATEWAY must be set when using foreman for provisioning
if [ "$FOREMAN_PROVISIONING" = "true" ]; then
if [ "x$FOREMAN_GATEWAY" = "x" ]; then
  echo "You must define FOREMAN_GATEWAY before running this script"
  echo "  Use either the gateway IP for the internal Foreman network, or"
  echo "  use 'false' to have no gateway offered for non-routable networks"
  exit 1
fi
fi

if [ "x$SCL_RUBY_HOME" = "x" ]; then
  SCL_RUBY_HOME=/opt/rh/ruby193/root
fi

if [ "x$OPNFV_PUPPET_HOME" = "x" ]; then
  OPNFV_PUPPET_HOME=/usr/share/opnfv/
fi

if [ "x$OPENSTACK_PUPPET_HOME" = "x" ]; then
  OPENSTACK_PUPPET_HOME=/usr/share/openstack-puppet
fi

if [ "x$QUICKSTACK_HOME" = "x" ]; then
  QUICKSTACK_HOME=$(cd $(dirname ${BASH_SOURCE[0]})/.. && pwd)
fi

if [ "x$FOREMAN_INSTALLER_DIR" = "x" ]; then
  FOREMAN_INSTALLER_DIR=/usr/share/foreman-installer
fi

if [ "x$FOREMAN_DIR" = "x" ]; then
  FOREMAN_DIR=/usr/share/foreman
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
    cat /etc/redhat-release | egrep -v -q 'release [7-9]|release [1-9][0-9]|release 6.[4-9]|release 6.[1-9][0-9]'; then
  echo "This installer is only supported on RHEL 6.4 or greater."
  exit 1
fi

if [ "$FOREMAN_PROVISIONING" = "true" ]; then

  PRIMARY_INT=$(route|grep default|awk ' { print ( $(NF) ) }')
  PRIMARY_PREFIX=$(facter network_${PRIMARY_INT} | cut -d. -f1-3)
 
  # If no provisioning interface specified, we want the first interface (mgmt) for OPNFV 
  if [ "x$PROVISIONING_INTERFACE" = "x" ]; then
    PROVISIONING_INTERFACE=$(facter -p|grep ipaddress_|grep -Ev "_lo"|awk -F"[_ ]" '{print $2;exit 0}')
  fi

  # the string for this interface that facter expects
  FACTER_PROV_INTERFACE=$( echo ${PROVISIONING_INTERFACE} | tr '.' '_' | tr '-' '_' )

  # Read the first three units of the IP network
  PROVISIONING_PREFIX=$(facter network_${FACTER_PROV_INTERFACE} | cut -d. -f1-3)

  if [ "x$PROVISIONING_PREFIX" = "x" ]; then
    echo "This installer can not determine the interface to provision over."
    exit 1
  fi     
  PROVISIONING_REVERSE=$(echo "$PROVISIONING_PREFIX" | ( IFS='.' read a b c ; echo "$c.$b.$a.in-addr.arpa" ))
  FORWARDER=$(augtool get /files/etc/resolv.conf/nameserver[1] | awk '{printf $NF}')
fi

# start with a subscribed RHEL6 box.  hint:
#    subscription-manager register
#    subscription-manager subscribe --auto

# enable ip forwarding
sudo sysctl -w net.ipv4.ip_forward=1
sudo sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf

# Puppet configuration
augtool -s <<EOA
set /files/etc/puppet/puppet.conf/agent/server $PUPPETMASTER
set /files/etc/puppet/puppet.conf/main/pluginsync true
EOA

# fix db migrate script for scl
cp ../config/dbmigrate $FOREMAN_DIR/extras/
# fix broken passenger config file for scl
cp ../config/broker-ruby $FOREMAN_DIR
chmod 775 $FOREMAN_DIR/broker-ruby

pushd $FOREMAN_INSTALLER_DIR
cat > installer.pp << EOM
class { 'puppet':
  runmode => 'cron',
  server  => true,
  server_common_modules_path => [
    '$QUICKSTACK_HOME/puppet/modules',
    '$OPENSTACK_PUPPET_HOME/modules',
    '$OPNFV_PUPPET_HOME/modules',
  ],
}

class { 'foreman':
  db_type => 'postgresql',
  custom_repo => true
}
#
# Check foreman_proxy/manifests/{init,params}.pp for other options
class { 'foreman_proxy':
  custom_repo          => true,
  port                 => '9090',
  registered_proxy_url => "https://\${::fqdn}:9090",
EOM

if [ "$FOREMAN_PROVISIONING" = "true" ]; then
cat >> installer.pp << EOM
  tftp_servername  => '$(facter ipaddress_${FACTER_PROV_INTERFACE})',
  dhcp             => true,
  dhcp_gateway     => '${FOREMAN_GATEWAY}',
  dhcp_range       => '${PROVISIONING_PREFIX}.50 ${PROVISIONING_PREFIX}.100',
  dhcp_interface   => '${FACTER_PROV_INTERFACE}',

  dns              => true,
  dns_reverse      => '${PROVISIONING_REVERSE}',
  dns_forwarders   => ['${FORWARDER}'],
  dns_interface    => '${FACTER_PROV_INTERFACE}',

  bmc              => true,
  bmc_default_provider => 'ipmitool',
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

puppet apply --verbose installer.pp --modulepath=modules

#
#  YuUCK ....
#
# The foreman installer puppet modules don't handle interface names well, so
#  we need to tweak this once again ...
#
# TODO fix this! But may require change to the foreman-installer puppet code itself.
#
sed -i "s#${FACTER_PROV_INTERFACE}#${PROVISIONING_INTERFACE}#" /etc/sysconfig/dhcpd
service dhcpd restart

popd

# turn on certificate autosigning
# GSutcliffe: Should be uneccessary once Foreman Provisioning is shown to be working
echo '*' >> /etc/puppet/autosign.conf

# Import puppet class definitions into Foreman
sudo -u foreman scl enable ruby193 "cd $FOREMAN_DIR; RAILS_ENV=production rake puppet:import:puppet_classes[batch]"


FOREMAN_VERSION_MAJOR=$(rpm -q foreman | cut -d'-' -f2 | cut -d'.' -f1)
FOREMAN_VERSION_MINOR=$(rpm -q foreman | cut -d'-' -f2 | cut -d'.' -f2)
# Set params, and run the db:seed file to set class parameter defaults
if [[ "$FOREMAN_VERSION_MAJOR" > 1 || "$FOREMAN_VERSION_MINOR" > 4 ]]; then
  cp ./opnfv-seeds.rb $FOREMAN_DIR/db/seeds.d/99-quickstack.rb
  sed -i "s#PROVISIONING_INTERFACE#$PROVISIONING_INTERFACE#" $FOREMAN_DIR/db/seeds.d/99-quickstack.rb
else
  cp ./seeds.rb $FOREMAN_DIR/db/.
  sed -i "s#PROVISIONING_INTERFACE#$PROVISIONING_INTERFACE#" $FOREMAN_DIR/db/seeds.rb
fi
sudo -u foreman scl enable ruby193 "cd $FOREMAN_DIR; rake db:seed RAILS_ENV=production FOREMAN_PROVISIONING=$FOREMAN_PROVISIONING"

#if [ "$FOREMAN_PROVISIONING" = "true" ]; then
  # Write the TFTP default file
  # this will not work until we call foreman-rake permissions:reset and use the
  # returned password
  #curl --user 'admin:changeme' -k 'https://127.0.0.1/api/config_templates/build_pxe_default'
#fi

# write client-register-to-foreman script
# TODO don't hit yum unless packages are not installed
cat >/tmp/foreman_client.sh <<EOF

# start with a subscribed RHEL6 box needs optional channels and epel
yum install -y augeas puppet nc

# Puppet configuration
augtool -s <<EOA
set /files/etc/puppet/puppet.conf/agent/server $PUPPETMASTER
set /files/etc/puppet/puppet.conf/main/pluginsync true
EOA

# check in to foreman
puppet agent --test
sleep 1
puppet agent --test

service puppet start
chkconfig puppet on

echo "NOTE: If you saw an error above including:
'Warning: 400 on SERVER: Failed to find....'
This may be ignored, as it means this host was unknown to Foreman at the start
of the Puppet run."
EOF

echo "Foreman is installed and almost ready for setting up your OpenStack"
echo "You'll find Foreman at https://$(hostname)"
echo "Get an admin password by running foreman-rake permissions:reset"
echo ""
echo "Then you need to alter a few parameters in Foreman."
echo "Visit: https://$(hostname)/hostgroups"
echo "From this list, click on each class that you plan to use"
echo "Go to the Smart Class Parameters tab and work though each of the parameters"
echo "in the left-hand column"
echo ""
echo "Then copy /tmp/foreman_client.sh to your openstack client nodes"
echo "Run that script and visit the HOSTS tab in foreman. Pick some"
echo "host groups for your nodes based on the configuration you prefer"
echo ""
echo "Once puppet runs on the machines, OpenStack is ready!"
if [ "$FOREMAN_PROVISIONING" = "true" ]; then
    echo "To finish configuring your provisioning setup, you need a"
    echo "TFTP default file, which can be set up by going to"
    echo "https://$(hostname)/config_templates/build_pxe_default"
fi
