require 'spec_helper'

# load enc fixture data
enc_fixture_data = hash_from_fixture_yaml_file('unit/node_parameters/foreman.yaml')

puppet_debug = false

# configure rspec
RSpec.configure do |c|
  c.default_node_params = enc_fixture_data['parameters']
  if puppet_debug
    c.before(:each) do
      Puppet::Util::Log.level = :debug
      Puppet::Util::Log.newdestination(:console)
    end
  end
end

start_params_for_class = {}
start_node_parameters = enc_fixture_data['parameters']

describe 'foreman_network' do
  # set default puppet environment
  let(:environment) { enc_fixture_data['environment'] }
  let(:params) { start_params_for_class }
  let(:node_params) { start_node_parameters }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      describe 'Compiles the catalog' do
        it { is_expected.to compile.with_all_deps }
      end

      describe 'test happy path' do
        it {
          is_expected.to contain_network_config('eth0').with(
            'ensure'    => 'present',
            'family'    => 'inet',
            'ipaddress' => '10.241.60.21',
            'method'    => 'static',
            'netmask'   => '255.255.255.0',
          )
          is_expected.to contain_network_config('eth1').with(
            'ensure'    => 'present',
            'family'    => 'inet',
            'ipaddress' => '10.241.90.104',
            'method'    => 'static',
            'netmask'   => '255.255.255.0',
          )
          is_expected.to contain_network_config('eth2').with(
            'ensure'  => 'present',
            'family'  => 'inet',
            'method'  => 'dhcp',
          )
          is_expected.to contain_network_route('0.0.0.0/0').with(
            'ensure'    => 'present',
            'gateway'   => '10.241.60.254',
            'interface' => 'eth0',
            'netmask'   => '0.0.0.0',
            'network'   => '0.0.0.0',
          )
          is_expected.to contain_class('resolv_conf')

          is_expected.to contain_network_config('eth0').that_notifies('Foreman_networking::Network_restart[eth0]')
          is_expected.to contain_network_config('eth1').that_notifies('Foreman_networking::Network_restart[eth1]')
          is_expected.to contain_network_config('eth2').that_notifies('Foreman_networking::Network_restart[eth2]')
          is_expected.to contain_network_route('0.0.0.0/0').that_notifies('Foreman_networking::Network_restart[eth0]')
        }
      end

      describe 'test overrides' do
        let(:params) do
          super().merge('route_overrides' => {
                          '0.0.0.0/0' => {
                            'ensure' => 'present',
                            'gateway' => '10.241.60.253',
                            'interface' => 'eth0',
                            'netmask' => '255.255.255.0',
                            'network' => '10.241.60.0',
                          },
                          '10.1.2.0/24' => {
                            'ensure' => 'present',
                            'gateway' => '10.1.2.254',
                            'interface' => 'eth0',
                            'netmask' => '255.255.255.0',
                            'network' => '10.1.2.0',
                          },
                        },
                        'nameservers' => [
                          '10.241.40.13',
                          '10.241.10.254',
                        ])
        end

        it {
          is_expected.to contain_network_route('0.0.0.0/0').with(
            'gateway' => '10.241.60.253',
          )
          is_expected.to contain_network_route('10.1.2.0/24').with(
            'ensure'    => 'present',
            'gateway'   => '10.1.2.254',
            'interface' => 'eth0',
            'netmask'   => '255.255.255.0',
            'network'   => '10.1.2.0',
          )
          is_expected.to contain_class('resolv_conf')
          is_expected.to contain_network_route('0.0.0.0/0').that_notifies('Foreman_networking::Network_restart[eth0]')
          is_expected.to contain_network_route('10.1.2.0/24').that_notifies('Foreman_networking::Network_restart[eth0]')
        }
      end
    end
  end
end
