module Puppet::Parser::Functions
  newfunction(:quick_include, :arity => 1, :doc => "Like hiera_include
  function. Using an array as first and only parameter instead
  ") do |args|
    answer = args[0]
    if answer && !answer.empty?
      method = Puppet::Parser::Functions.function(:include)
      send(method, [answer])
    else
      raise Puppet::ParseError, "Could not find data item #{answer}"
    end
  end
end
