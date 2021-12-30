#!/usr/bin/env bash
# exit on error
set -o errexit

bin/bundle install
bin/rails db:migrate
