module VCAP::CloudController
  module Concerns
    module UsesBitsService
      extend ActiveSupport::Concern

      private

      def use_bits_service?
        CloudController::DependencyLocator.instance.use_bits_service
      end

      def bits_client
        CloudController::DependencyLocator.instance.bits_client
      end
    end
  end
end
