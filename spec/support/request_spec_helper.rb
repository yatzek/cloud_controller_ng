module RequestSpecHelper
  ENV['RACK_ENV'] = 'test'

  def app
    test_config     = TestConfig.config
    request_metrics = Metrics::RequestMetrics.new
    RackAppBuilder.new.build test_config, request_metrics
  end
end
