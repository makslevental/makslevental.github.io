#!/usr/bin/env bash
# brew install ruby (system ruby 2.6 is too old)
export PATH=/opt/homebrew/opt/ruby/bin:$PATH
bundle config set --local path vendor/bundle
bundle install
bundle exec jekyll serve -w -l
