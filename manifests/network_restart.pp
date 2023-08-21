# @summary Restart a network interface
#
# Apply configuration changes for a network interface
#
# @param interface
#   The network interface identifier eg. eth0
#
# @param manage_network_interface_restart
#   if true the network interface will be restarted
#
define foreman_network::network_restart (
  String $interface,
  Boolean $manage_network_interface_restart = $foreman_network::manage_network_interface_restart
) {
  if $manage_network_interface_restart {
    exec { "network_restart_${interface}":
      command     => "ifdown ${interface} --force ; ifup ${interface}",
      path        => '/bin:/usr/bin:/sbin:/usr/sbin',
      refreshonly => true,
    }
  }
}
