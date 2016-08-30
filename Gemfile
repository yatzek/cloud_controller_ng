source 'https://rubygems.org'

gem 'addressable'
gem 'railties', '~> 4.2.7.1'
gem 'rake'

# nats wants to lock us to an older version. we already use eventmachine 1.0.9, so do not want a downgrade.
gem 'eventmachine', '~> 1.2'

gem 'fog'
gem 'i18n'
gem 'nokogiri', '~> 1.6.8'
gem 'unf'
gem 'netaddr'
gem 'rfc822'
gem 'sequel'
gem 'sinatra', '~> 1.4'
gem 'sinatra-contrib'
gem 'multi_json'
gem 'yajl-ruby'
gem 'mime-types', '~> 3.1'
gem 'membrane', '~> 1.0'
gem 'httpclient'
gem 'steno'
gem 'cloudfront-signer'
gem 'vcap_common', '4.0.5'
gem 'allowy'
gem 'loggregator_emitter', '~> 5.0'
gem 'delayed_job_sequel', git: 'https://github.com/cloudfoundry/delayed_job_sequel.git'
gem 'thin', '~> 1.6.0'
gem 'newrelic_rpm', '~>3.16.2.321'
gem 'clockwork', require: false
gem 'statsd-ruby'
gem 'activemodel', '~> 4.2.7.1'
gem 'actionpack', '~> 4.2.7.1'
gem 'actionview', '~> 4.2.7.1'
gem 'public_suffix'

gem 'nats', '0.8.0'

# We need to use https for git urls as the git protocol is blocked by various firewalls
gem 'vcap-concurrency', git: 'https://github.com/cloudfoundry/vcap-concurrency.git', ref: 'f80806310f121118f0638728fb1c1e94a57bd623'
gem 'cf-uaa-lib', '~> 3.6'
gem 'cf-message-bus', '~> 0.3'
gem 'bits_service_client', github: 'cloudfoundry-incubator/bits-service-client'

group :db do
  gem 'mysql2', '0.4.4'
  gem 'pg', '~>0.18.4'
end

group :operations do
  gem 'pry-byebug'
  gem 'awesome_print'
end

group :test do
  gem 'codeclimate-test-reporter', require: false
  gem 'fakefs', require: 'fakefs/safe'
  gem 'machinist', '~> 2.0'
  gem 'parallel_tests'
  gem 'rack-test'
  gem 'rspec', '~> 3.5.0'
  gem 'rspec-instafail'
  gem 'rspec_api_documentation', git: 'https://github.com/zipmark/rspec_api_documentation.git'
  gem 'rspec-collection_matchers'
  gem 'rspec-its'
  gem 'rspec-rails'
  gem 'rubocop'
  gem 'timecop'
  gem 'webmock', '~> 2.1.0'
end

group :development do
  gem 'roodi'
  gem 'ruby-debug-ide'
  gem 'byebug'
end
