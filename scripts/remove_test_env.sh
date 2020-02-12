#!/bin/sh
# Run all commands to destroy the litmus test environment
# ATTENTION: run this script from the root directory of the module
bundle exec rake litmus:tear_down
