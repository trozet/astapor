Facter.add("hamysql_is_running") do

  setcode do
    if File.exist? "/usr/sbin/pcs"
      a = Facter::Util::Resolution.exec("/usr/sbin/pcs status 2>/dev/null | grep -P 'mysql-ostk-mysql\\s.*Started'")
      a != nil and a.length > 0
    else
     false
    end
  end
end
