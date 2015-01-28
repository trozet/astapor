require 'facter/util/ip'
module Puppet::Parser::Functions
  newfunction(:is_configured, :type => :rvalue, :doc => <<-EOS
check if a service is set up in pacemaker or not
EOS
  ) do |arguments|

    raise(Puppet::ParseError, "is_configured(): Wrong number of arguments " +
      "given (#{arguments.size} for 1)") if arguments.size < 1

    the_service= arguments[0]
    pcs_fact = lookupvar("::pcs_setup_#{the_service}")

    if (pcs_fact.nil? || pcs_fact == false)
      return false
    else
      return true
    end
  end
end
