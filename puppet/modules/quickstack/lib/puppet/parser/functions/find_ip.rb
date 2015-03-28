require 'facter/util/ip' 
module Puppet::Parser::Functions
    newfunction(:find_ip, :type => :rvalue, :doc => <<-EOS
This returns the ip associated with the given network or nic. 
                EOS
) do |arguments|
    Puppet::Parser::Functions.autoloader.loadall
    raise(Puppet::ParseError, "find_ip(): Wrong number of arguments " +
      "given (#{arguments.size} for 3)") if arguments.size < 3

    the_network= arguments[0] ||= ''
    the_nic = arguments[1] ||= ''
    the_ip = arguments[2] ||= ''

    if (the_ip != '')
      the_ip
    elsif (the_nic != '')
      my_ip = nil
      [the_nic].flatten.each do |this_nic|
        if !function_get_ip_from_nic([this_nic]).nil?
          my_ip = function_get_ip_from_nic([this_nic])
          break
        end
      end
      my_ip
    else
      function_get_ip_from_network([the_network])
    end
  end
end
