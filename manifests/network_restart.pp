# @summary Restart a network interface
#
# Apply configuration changes for a network interface
#
# @param interface
#   The network interface identifier eg. eth0
# @param mange_network_interface_restart
#   if true the network interface will be restarted
#
define foreman_network::network_restart (
  String $interface,
  Boolean $mange_network_interface_restart = $foreman_network::mange_network_interface_restart
) {
  if $mange_network_interface_restart {
    exec { "network_restart_${interface}":
      command     => "ifdown ${interface} --force ; ifup ${interface}",
      path        => '/sbin',
      refreshonly => true,
    }
  }
}
