#!/bin/sh
# Install all dependecies for a working testing environment
# ATTENTION: run this script from the root directory of the module
gem install bundle
gem install puppet
gem install yard
gem install puppet-strings
gem install github_changelog_generator
bundle install --path .bundle/gems/