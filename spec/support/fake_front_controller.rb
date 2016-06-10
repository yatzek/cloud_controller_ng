require 'support/fake_nginx_reverse_proxy'

class FakeFrontController < FrontController
  use(FakeNginxReverseProxy)

  def initialize(config)
    super(config)
  end
end
