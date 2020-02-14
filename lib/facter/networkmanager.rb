Facter.add('networkmanager') do
  confine :kernel => 'Linux'
  setcode do
    nmcli_cmd = Facter::Core::Execution.which('nmcli')
    if File.exist? nmcli_cmd
      begin
        exit_code = Facter::Core::Execution.execute("#{nmcli_cmd} g > /dev/null; echo $?", { :on_fail => :raise })
        result = 'active'
        if exit_code != "0"
          result = 'inactive'
        end
      rescue Facter::Core::Execution::ExecutionFailure
        result = 'inactive'
      end
    else
      result = 'inactive'
    end
    result
  end
end