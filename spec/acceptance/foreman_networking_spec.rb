require 'spec_helper_acceptance'

hiera_fixture_data_static = hash_from_fixture_yaml_file('acceptance/data/common.yaml')
hiera_fixture_data_dhcp = hash_from_fixture_yaml_file('acceptance/data/dhcp.yaml')

pp_static_if = <<-PUPPETCODE
    class { 'foreman_network':
      * => #{hiera_fixture_data_static}
    }
PUPPETCODE

pp_dhcp_if = <<-PUPPETCODE
    class { 'foreman_network':
      * => #{hiera_fixture_data_dhcp}
    }
PUPPETCODE

# Set Env Variables
#ENV['RSPEC_DEBUG'] = 'true'
ENV['LANG'] = 'C'
ENV['LC_ALL'] = 'C'

describe 'Execute Class' do
  context 'applies with dhcp interface configuration' do
    it { apply_manifest(pp_dhcp_if) }
  end

  context 'check configuration for dhcp interface config' do
    describe file('/etc/resolv.conf.test_dhcp') do
      it { is_expected.not_to exist }
    end

    describe interface('eth0') do
      its(:ipv4_address) { is_expected.not_to match %r{172\.17\.0\.} }
    end

    describe command('ip route list') do
      its(:stdout) { is_expected.to contain('') }
    end
  end

  context 'applies with static interface config' do
    it { apply_manifest(pp_static_if) }
  end

  context 'check configuration for static interface config' do
    describe interface('eth0') do
      it do
        is_expected.to be_up
        is_expected.to have_ipv4_address('172.17.0.3')
      end
    end

    describe routing_table do
      it do
        is_expected.to have_entry(
          destination: 'default',
          interface: 'eth0',
          gateway: '172.17.0.1',
        )
        is_expected.to have_entry(
          destination: '10.1.5.0/24',
          interface: 'eth0',
          gateway: '172.17.0.3',
        )
      end
    end

    describe file('/etc/resolv.conf.test_static') do
      it { is_expected.to be_readable.by_user('root') }
      its(:content) do
        is_expected.to match %r{search dmz.test.de}
        is_expected.to match %r{nameserver 10.241.40.11}
        is_expected.to match %r{nameserver 10.241.40.12}
        is_expected.to match %r{nameserver 192.168.65.1}
      end
    end
  end
end
