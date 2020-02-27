# foreman_network

#### Table of Contents

- [Overview](#overview)
- [Requirements](#requirements)
  * [Beginning with foreman_network](#beginning-with-foreman_network)
- [Usage](#usage)
  * [Install and enable foreman_network](#install-and-enable-foreman_network)
  * [Declare foreman_network](#declare-foreman_network)
  * [Configure nameservers](#configure-nameservers)
    + [Additional nameservers](#additional-nameservers)
    + [Custom nameservers](#custom-nameservers)
  * [Overwrite network routes](#overwrite-network-routes)
    + [Add static route and overwrite the default gateway on interface eth0](#add-static-route-and-overwrite-the-default-gateway-on-interface-eth0)
- [Reference](#reference)
- [Limitations](#limitations)
- [Development](#development)
  * [Setup testing and development environment (MacOSX)](#setup-testing-and-development-environment--macosx-)
  * [Running acceptance tests](#running-acceptance-tests)
  * [Running unit tests](#running-unit-tests)
  * [Updating documentation](#updating-documentation)
- [Release Notes](#release-notes)


## Overview

This module configures network interfaces, network routes and resolv.conf from Foreman ENC (external node classifier) node parameters.

Basically it parses the foreman_interfaces and domainname node parameters from foreman and pass it to other puppet modules to configure the settings.

More information about foreman: https://theforeman.org/

Information about Puppet ENC (external node classifier): https://puppet.com/docs/puppet/latest/nodes_external.html

## Requirements

* Puppet >= 4.10.0 < 7.0.0
* [puppetlabs/stdlib](https://github.com/puppetlabs/puppetlabs-stdlib)
* [puppet/network](https://github.com/voxpupuli/puppet-network)
* [saz/resolv_conf](https://github.com/saz/puppet-resolv_conf)

### Beginning with foreman_network
All parameters for the module are contained within the main class, so for any function of the module, set the options you want. All configuration parameters can be assigned hiera. The default values are also lookuped up by hiera. See the common usages below for examples.

## Usage

### Install and enable foreman_network
```
include foreman_network
```

### Declare foreman_network 
To get foreman_network up and running just declare the class.

```
class { 'foreman_network': }
```

Declare the class with default values:
```
class { 'foreman_network':
  nameservers                     => [],
  nameservers_merge               => true,
  manage_resolv_conf              => true,
  route_overrides                 => {},
  mange_network_interface_restart => true,
  manage_if_from_facts_only       => true,
  resolv_conf_path                => '/etc/resolv.conf',
  debug                           => false,
  searchpath_merge                => true,
  searchpath                      => [],
}
```

Using Hiera with default values:

```
foreman_network:
  nameservers: []
  nameservers_merge: true
  manage_resolv_conf: true
  route_overrides: {}
  mange_network_interface_restart: true
  manage_if_from_facts_only: true
  resolv_conf_path: /etc/resolv.conf
  debug: false
  searchpath_merge: true
  searchpath: []
```

### Configure nameservers 

**IMPORTANT: When the boot mode of the primary interface from foreman is a DHCP, the resolv.conf will be always unmanaged even when the parameter manage_resolv_conf is true.**

#### Additional nameservers
Foreman passes 2 nameservers via node parameters: dns_primary (eg. 1.1.1.1) and dns_secondary (eg. 2.2.2.2). 

With the following configuration additional nameservers will be added via an unique merge:

```
class { 'foreman_network':
  nameservers_merge  => true,
  nameservers        => [
    '1.1.1.1',
    '8.8.8.8',
    '4.4.4.4'
  ],
}
```

Using Hiera:

```
foreman_network:
  nameservers_merge: true
  nameservers:
    - 8.8.8.8
    - 4.4.4.4
```

The result in /etc/resolv.conf will be:
```
[...]
nameserver 1.1.1.1
nameserver 2.2.2.2
nameserver 8.8.8.8
nameserver 4.4.4.4
[...]
```

#### Custom nameservers

Use custom nameservers and ignore foreman nameservers with the following configuration

```
class { 'foreman_network':
  nameservers_merge  => false,
  nameservers        => [
    '8.8.8.8',
    '4.4.4.4'
  ],
}
```

Using Hiera:

```
foreman_network:
  nameservers_merge: false
  nameservers:
    - 8.8.8.8
    - 4.4.4.4
```

The result in /etc/resolv.conf will be:
```
[...]
nameserver 8.8.8.8
nameserver 4.4.4.4
[...]
```

### Overwrite network routes

**IMPORTANT: When the boot mode of the primary interface from foreman is a DHCP, all routes for this interface will be ignored**
**IMPORTANT: When NetworkManager is enabled no static routes will be set**

#### Add static route and overwrite the default gateway on interface eth0

```
class { 'foreman_network':
  route_overrides => {
    '0.0.0.0/0'   => {
      'ensure'    => 'present',
      'gateway'   => '10.241.60.253',
      'interface' => 'eth0',
      'netmask'   => '255.255.255.0',
      'network'   => '10.241.60.0',
    },
    '10.1.2.0/24' => {
      'ensure'    => 'present',
      'gateway'   => '10.1.2.254',
      'interface' => 'eth0',
      'netmask'   => '255.255.255.0',
      'network'   => '10.1.2.0',
    },
  }
}
```

Using Hiera:

```
foreman_network:
  route_overrides:
    0.0.0.0/24:
      ensure: present
      gateway: 10.241.60.253
      interface: eth0
      netmask: 255.255.255.0
      network: 10.241.60.0 
    10.1.2.0/24:
      ensure: present
      gateway: 10.1.2.254
      interface: eth0
      netmask: 255.255.255.0
      network: 10.1.2.0  
```

## Reference

See [REFERENCE.md](REFERENCE.md)

## Limitations

For a list of supported operating systems, see [metadata.json](metadata.json)

## Development

This module uses [puppet_litmus](https://github.com/puppetlabs/puppet_litmus) for development and acceptance testing.

### Setup testing and development environment (MacOSX)

Install required software with [brew](https://brew.sh/)
```
brew cask install docker
brew cask install puppetlabs/puppet/pdk
brew cask install puppet-bolt
brew install rbenv
rbenv init
echo 'eval "$(rbenv init -)"' >> $HOME/.zshrc
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-doctor | bash
rbenv install 2.6.5
```

Install all needed gem dependencies:
```
./scripts/prepare_test_env.sh
```

### Running acceptance tests

Create test environment:
```
./scripts/create_test_env.sh
```

Run the acceptance tests:
```
./scripts/run_tests.sh
```

Remove the test environment:
```
./scripts/remove_test_env.sh
```

### Running unit tests
```
pdk test unit
```

### Updating documentation

Update REFERENCE.md
```
puppet strings generate --format markdown
```

Generate TOC

https://ecotrust-canada.github.io/markdown-toc/

## Release Notes

See [CHANGELOG.md](CHANGELOG.md)