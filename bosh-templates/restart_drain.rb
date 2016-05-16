#!/var/vcap/packages/ruby-2.3/bin/ruby --disable-all

$LOAD_PATH.unshift('/var/vcap/packages/ss/ss/app')
$LOAD_PATH.unshift('/var/vcap/packages/ss/ss/lib')

require 'cloud_controller/drain'

@drain = VCAP::CloudController::Drain.new('/var/vcap/sys/log/cloud_controller_ng')
@drain.log_invocation(ARGV)
@drain.shutdown_nginx('/var/vcap/sys/run/nginx_cc/nginx.pid')
@drain.shutdown_cc('/var/vcap/sys/run/cloud_controller_ng/cloud_controller_ng.pid')

puts 0 # tell bosh the drain script succeeded
