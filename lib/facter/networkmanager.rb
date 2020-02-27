Facter.add('networkmanager') do
  confine kernel: 'Linux'
  setcode do
    result = 'inactive'
    nmcli_cmd = Facter::Core::Execution.which('nmcli')
    unless nmcli_cmd.nil?
      if File.exist?(nmcli_cmd)
        begin
          exit_code = Facter::Core::Execution.execute("#{nmcli_cmd} g > /dev/null; echo $?", on_fail: :raise)
          result = 'active'
          if exit_code != '0'
            result = 'inactive'
          end
        rescue Facter::Core::Execution::ExecutionFailure
          result = 'inactive'
        end
      else
        result = 'inactive'
      end
    end
    result
  end
end
