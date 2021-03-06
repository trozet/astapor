require 'facter/util/ip' 
module Puppet::Parser::Functions
  newfunction(:get_netmask_from_nic, :type => :rvalue, :doc => <<-EOS
This returns the netmask associatd with the given interface name.
EOS
  ) do |arguments|

    raise(Puppet::ParseError, "get_netmask_from_nic(): Wrong number of arguments " +
      "given (#{arguments.size} for 1)") if arguments.size < 1

    if (arguments[0] == nil)
      return nil
    end
    the_nic = arguments[0].gsub(/[.:-]+/,'_')
    netmask = lookupvar("netmask_#{the_nic}")

    return netmask
  end 
end
