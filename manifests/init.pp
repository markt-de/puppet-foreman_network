# == Class: foreman_network
#
# @summary Configure network interfaces, routes and resolv.conf from foreman ENC node parametes
#
# @param foreman_interfaces
#   ENC node parameter with key foreman_interfaces injected by foreman
# @param searchpath
#   Search list for host-name lookup in resolv.conf. Use ENC node parameter domainname from foreman as default
# @param nameservers
#   List of nameservers which will be either exclusive used or merged. Depends on nameservers_merge
# @param nameservers_merge
#   if true merges the entries the foreman dns servers with nameservers. if false then only use nameserver
# @param manage_resolv_conf
#   Specify wether to manage resolve.conf or not.
#   IMPORTANT: If DHCP is enabled on the primary interface resolv.conf will always be unmanged.
# @param route_overrides
#   Overrides the default route provided by foreman and could also add additional static network routes.
#   IMPORTANT: If DHCP enabled is enabled on the primary interface. All routes on the primary interface will be ignored.
# @param mange_network_interface_restart
#   True means the network interface will be configured (if down & up) immediately on change
# @param manage_if_from_facts_only
#   If true then only interfaces will be managed that exists in $facts['networking']['interfaces']
# @param resolv_conf_path
#   The path of the resolv.conf. For docker accaptance test this could be modified
# @param debug
#   Turn on debug mode
#
class foreman_network (
  Array $foreman_interfaces = $::foreman_interfaces,
  Array $searchpath = [ $::domainname ],
  Array $nameservers,
  Boolean $nameservers_merge,
  Boolean $manage_resolv_conf,
  Hash $route_overrides,
  Boolean $mange_network_interface_restart,
  Boolean $manage_if_from_facts_only,
  Stdlib::Compat::Absolute_path $resolv_conf_path,
  Boolean $debug
) {

  # get default route and resolv.conf data from the primary foreman interface
  $primary_interface = $foreman_interfaces.filter |Hash $v| { $v['primary'] == true }[0]

  if $primary_interface {

    $foreman_default_route = {
      '0.0.0.0/0' => {
        'ensure'    => 'present',
        'gateway'   => $primary_interface['subnet']['gateway'],
        'interface' => $primary_interface['identifier'],
        'netmask'   => '0.0.0.0',
        'network'   => '0.0.0.0',
      }
    }

    if $primary_interface['subnet']['boot_mode'] == 'DHCP' {
      # only static routes for primary dhcp interfaces
      $network_route_data = $route_overrides
    } else {
      $network_route_data = $foreman_default_route + $route_overrides
    }

    $foreman_nameserver = [
      $primary_interface['subnet']['dns_primary'],
      $primary_interface['subnet']['dns_secondary']
    ]

    if $nameservers_merge {
      $real_nameservers = unique($foreman_nameserver + $nameservers)
    }
    else {
      $real_nameservers = $nameservers
    }

    $network_resolv_conf = {
      'nameservers' => $real_nameservers,
      'searchpath' => $searchpath
    }
  }

  # get network interface config data from foreman_interfaces
  $network_config_data = $foreman_interfaces.map |Integer $index, Hash $foreman_interface| {
    $interface_id = $foreman_interface['identifier']

    # IPv4 only
    $ip = $foreman_interface['ip']
    $netmask = $foreman_interface['subnet']['mask']
    $interface_mode = $foreman_interface['subnet']['boot_mode']

    if $interface_mode == 'Static' {
      $interface_data = {
        'ensure'    => 'present',
        'family'    => 'inet',
        'ipaddress' => $ip,
        'method'    => 'static',
        'netmask'   => $netmask,
      }
    }
    elsif $interface_mode == 'DHCP' {
      $interface_data = {
        'ensure'  => 'present',
        'family'  => 'inet',
        'method'  => 'dhcp',
      }
    }

    $result = {
      $interface_id => $interface_data
    }
  }

  # manage resolv.conf only on primary non dhcp interface
  if (
    $manage_resolv_conf
      and $primary_interface['subnet']['boot_mode'] != 'DHCP'
  ) {
    class { '::resolv_conf':
        *           => $network_resolv_conf,
        config_file => $resolv_conf_path,
    }
  }

  # manage interfaces
  $network_config_data.each |Hash $resource| {
    $resource.map |$interface, $config| {
      # instance network interface restart resources
      foreman_network::network_restart{ $interface:
        interface => $interface
      }

      if (
        $manage_if_from_facts_only == true and has_key($facts['networking']['interfaces'], $interface)
        or $manage_if_from_facts_only == false
      ) {
        network_config { $interface:
          *      => $config,
          notify => Foreman_networking::Network_restart[$interface]
        }
      } else {
        warning("The interface: ${interface} does not exist in facts['networking']['interfaces'] or is a dhcp interface")
      }
    }
  }

  # manage routes
  $network_route_data.each |String $route, Hash $config| {
    if (
      $manage_if_from_facts_only == true and has_key($facts['networking']['interfaces'], $config['interface'])
        or $manage_if_from_facts_only == false
    ) {
      if (
        $primary_interface['subnet']['boot_mode'] == 'DHCP'
          and $config['interface'] == $primary_interface['identifier']
      ) {
        warning("Ignoring the route: ${route} because ${config['interface']} is primary and has dhcp enabled")
      } else {
        network_route { $route:
          *      => $config,
          notify => Foreman_networking::Network_restart[$config['interface']]
        }
      }
    } else {
      warning("The interface: ${config['interface']} for route ${route} does not exist in facts['networking']['interfaces'].")
    }
  }

  if($debug) {
    notify {"ENC data: foreman_interfaces ${foreman_interfaces} ": withpath => true, }
    notify {"ENC data: searchpath ${searchpath} ": withpath => true, }
    notify {"network_config_data ${network_config_data} ": withpath => true, }
    notify {"network_route_data ${network_route_data} ": withpath => true, }
    notify {"network_resolv_conf ${network_resolv_conf} ": withpath => true, }
  }

}
