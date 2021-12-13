source 'https://rubygems.org'

gem 'activesupport', '~> 4.0'
gem 'addressable', '= 2.3.5'
gem 'bcrypt', '~> 3.0'
gem 'cube-ruby', require: 'cube'
gem 'ffi'
gem 'libxml-ruby', '~> 2.0'
gem 'minitest', '~> 4.0'
gem 'multi_json', '~> 1.0'
gem 'oj', '~> 2.0'
gem 'omni_logger'
gem 'pony'
gem 'rack', '~> 1.0'
gem 'rack-test', '~> 0.6'
gem 'rake', '~> 10.0'
gem 'rest-client'
gem 'rsolr', '~> 1.0'
gem 'rubyzip', '~> 1.0'
gem 'thin'

# Testing
group :test do
  gem 'email_spec'
  gem 'minitest-reporters', '>= 0.5.0'
  gem 'pry'
  gem 'simplecov'
  gem 'test-unit-minitest'
end

group :development do
  gem 'rubocop', require: false
end

# NCBO gems (can be from a local dev path or from rubygems/git)
gem 'goo', github: 'ontoportal-lirmm/goo', branch: 'master'
gem 'sparql-client', github: 'ncbo/sparql-client', branch: 'master'

# ResourceIndex dependencies (managed per-platform)
gem 'ncbo_resource_index', github: 'ncbo/resource_index'
