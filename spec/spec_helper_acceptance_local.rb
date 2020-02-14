# frozen_string_literal: true

require 'puppet_litmus'
require 'singleton'
require 'tempfile'

class LitmusHelper
  include Singleton
  include PuppetLitmus
end

# load hash from a yaml file under fixtures
def hash_from_fixture_yaml_file(fixture_path)
  fixture_yaml_path = File.join(File.dirname(__FILE__), 'fixtures', fixture_path)
  yaml_file = File.read(fixture_yaml_path)
  YAML.safe_load(yaml_file)
end

# create a file on the test machine
def create_remote_file(name, dest_filepath, file_content)
  Tempfile.open name do |tempfile|
    File.open(tempfile.path, 'w') { |file| file.puts file_content }
    LitmusHelper.instance.bolt_upload_file(tempfile.path, dest_filepath)
  end
end

sysconfig_network = <<-EOS
# Created by puppet litmus
EOS

dhclient_eth0_conf = <<-EOS
# Created by puppet litmus
timeout 1;
try 1;
EOS

RSpec.configure do |c|
  c.before :suite do
    vmhostname = LitmusHelper.instance.run_shell('hostname').stdout.strip
    vmipaddr = LitmusHelper.instance.run_shell("ip route get 8.8.8.8 | awk '{print $NF; exit}'").stdout.strip
    if os[:family] == 'redhat'
      vmipaddr = LitmusHelper.instance.run_shell("ip route get 8.8.8.8 | awk '{print $7; exit}'").stdout.strip
    end
    vmos = os[:family]

    puts "Running acceptance test on #{vmhostname} with address #{vmipaddr} and OS #{vmos}"

    # setup redhat systems for acceptance tests
    if os[:family] == 'redhat'
      if vmipaddr.empty?
        LitmusHelper.instance.run_shell('puppet module install /tmp/andeman-foreman_network-1.0.0.tar.gz --ignore-dependencies')
      else
        # only install software from remote if we got an ip
        LitmusHelper.instance.run_shell('yum -y install iproute net-tools ruby dhclient NetworkManager')
        LitmusHelper.instance.run_shell('gem install ipaddress')
      end
      create_remote_file('sysconfig_network', '/etc/sysconfig/network', sysconfig_network)
      create_remote_file('dhclient_eth0_conf', '/etc/dhcp/dhclient-eth0.conf', dhclient_eth0_conf)
      LitmusHelper.instance.run_shell('rm /etc/sysconfig/network-scripts/ifcfg-eth0')
      LitmusHelper.instance.run_shell('rm /etc/sysconfig/network-scripts/route-eth0')
    end
  end
  c.before(:each, :NetworkManager => true) do
    puts "Starting Network Manager"
    LitmusHelper.instance.run_shell('systemctl start NetworkManager')
  end
  c.after(:each, :NetworkManager => true) do
    puts "Stopping Network Manager"
    LitmusHelper.instance.run_shell('systemctl stop NetworkManager')
  end
end
