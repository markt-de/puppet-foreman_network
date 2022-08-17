#!/bin/sh
provision_list=${1:-default}

pdk bundle exec rake "litmus:provision_list[${provision_list}]"
bundle exec rake litmus:install_agent
bundle exec rake litmus:install_module
