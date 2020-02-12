# @summary Contains the logic to
#
# A description of what this defined type does
#
# @example
#   foreman_network::network_restart { 'namevar': }
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
