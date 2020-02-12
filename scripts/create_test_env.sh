#!/bin/sh
# Runs all commands to create a working litmus test environment
# ATTENTION: run this script from the root directory of the module
bundle exec rake 'litmus:provision_list[default]'
cat > inventory.yaml <<_EOF_
---
version: 2
groups:
- name: docker_nodes
  targets:
  - uri: waffleimage_centos7_-2222
    transport: docker
    config:
      transport: docker
      docker:
        shell-command: bash -lc
    facts:
      provisioner: docker
      container_name: waffleimage_centos7_-2222
      platform: waffleimage/centos7
    features:
    - puppet-agent
- name: ssh_nodes
  targets: []
- name: winrm_nodes
  targets: []
_EOF_

bundle exec rake litmus:install_agent
bundle exec rake litmus:install_module