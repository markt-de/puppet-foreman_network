require 'spec_helper'

describe 'foreman_network::network_restart' do
  let(:title) { 'eth0' }
  let(:params) do
    {
      interface: 'eth0',
      manage_network_interface_restart: true,
    }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it {
        is_expected.to compile
        is_expected.to contain_exec('network_restart_eth0')
      }
    end
  end
end
