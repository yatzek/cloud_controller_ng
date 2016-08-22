require 'messages/base_message'

module VCAP::CloudController
  class ProcessCreateMessage < BaseMessage
    ALLOWED_KEYS = [
      :memory,
      :name,
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
      :route_guids
    ].freeze

    attr_accessor(*ALLOWED_KEYS)

    def self.create_from_http_request(body)
      ProcessCreateMessage.new(body.symbolize_keys)
    end

    validates :buildpack, string: true, allow_nil: true
    validates :disk_quota, numericality: { only_integer: true }, allow_nil: true
    validates :health_check_type, string: true, allow_nil: true
    validates :instances, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
    validates :state, string: true, allow_nil: true
    validates :docker_credentials_json, hash: true, allow_nil: true
    validates :ports, array: true, allow_nil: true
    validates :health_check_timeout, numericality: { only_integer: true }, allow_nil: true
    validates :route_guids, array: true, allow_nil: true
    validates :diego, inclusion: { in: [true, false] }, allow_nil: true
    validates :enable_ssh, inclusion: { in: [true, false] }, allow_nil: true
    validates :command, string: true, allow_nil: true
    validates :memory, numericality: { only_integer: true }, allow_nil: true

    private

    def allowed_keys
      ALLOWED_KEYS
    end
  end
end
