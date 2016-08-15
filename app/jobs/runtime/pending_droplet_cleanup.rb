module VCAP::CloudController
  module Jobs
    module Runtime
      class PendingDropletCleanup < VCAP::CloudController::Jobs::CCJob
        attr_accessor :expiration_in_seconds

        def initialize(expiration_in_seconds)
          @expiration_in_seconds = expiration_in_seconds
        end

        def perform
          DropletModel.where(state: [DropletModel::PENDING_STATE, DropletModel::STAGING_STATE]).where("updated_at < ? - INTERVAL '?' SECOND", Sequel::CURRENT_TIMESTAMP, expiration_in_seconds.to_i).update(
            state: DropletModel::FAILED_STATE,
            error_id: 'StagingTimeExpired'
          )
        end

        def job_name_in_configuration
          :pending_packages
        end

        def max_attempts
          1
        end
      end
    end
  end
end
