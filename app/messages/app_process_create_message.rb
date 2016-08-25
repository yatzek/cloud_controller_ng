require 'messages/base_message'

module VCAP::CloudController
  class AppProcessCreateMessage < BaseMessage
    ALLOWED_KEYS = [
      :name,
      :environment_json,
      :space_guid,
      :memory,
      :buildpack,
      :instances,
      :disk_quota,
      :state,
      :command,
      :health_check_type,
      :health_check_timeout,
      :diego,
      :enable_ssh,
      :docker_credentials_json,
      :ports,
      :stack_guid,
      :docker_image,
      :route_guids
    ].freeze

    attr_accessor(*ALLOWED_KEYS)


    def self.create_from_http_request(body)
      AppProcessCreateMessage.new(body.symbolize_keys)
    end

    validates_with NoAdditionalKeysValidator

    validates :name, string: true, presence: true, allow_nil: false
    validates :environment_json, hash: true, allow_nil: true
    validates :buildpack, string: true, allow_nil: true
    validates :disk_quota, numericality: { only_integer: true }, allow_nil: true
    validates :health_check_type, string: true, allow_nil: true
    validates :instances, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
    validates :state, string: true, allow_nil: true
    validates :docker_credentials_json, hash: true, allow_nil: true
    validates :ports, array: true, allow_nil: true, array_of_integers: true
    validates :health_check_timeout, numericality: { only_integer: true }, allow_nil: true
    validates :route_guids, array: true, allow_nil: true, array_of_guids: true
    validates :diego, inclusion: { in: [true, false] }, allow_nil: true
    validates :enable_ssh, inclusion: { in: [true, false] }, allow_nil: true
    validates :command, string: true, allow_nil: true
    validates :memory, numericality: { only_integer: true }, allow_nil: true

    def lifecycle
      if buildpack || stack_guid
        @lifecycle = {
          lifecycle: {
            type: 'buildpack',
            data: {
              buildpack: buildpack,
              stack: Stack.find(guid: stack_guid).try(:name)
            }
          }
        }
      elsif docker_image
        @lifecycle = {
          lifecycle: {
            type: 'docker',
            data: { image: docker_image }
          }
        }
      end
    end

    private

    def allowed_keys
      ALLOWED_KEYS
    end
  end
end
