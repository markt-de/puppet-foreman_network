#!/bin/sh
# execute the acceptence test
# ATTENTION: run this script from the root directory of the module
bundle exec rake litmus:reinstall_module &&
bundle exec rake litmus:acceptance:parallel

