module Diego
  module V3
    module LifecycleProtocol
      def self.protocol_for_type(lifecycle_type)
        if lifecycle_type == Lifecycles::BUILDPACK
          ::Diego::V3::Buildpack::LifecycleProtocol.new
        elsif lifecycle_type == Lifecycles::DOCKER
          ::Diego::V3::Docker::LifecycleProtocol.new
        end
      end
    end
  end
end
