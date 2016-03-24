require 'messages/base_message'

module VCAP::CloudController
  class AppsListMessage < BaseMessage
    ALLOWED_KEYS = [:names, :guids, :organization_guids, :space_guids, :page, :per_page, :order_by].freeze

    attr_accessor(*ALLOWED_KEYS)

    validates_with NoAdditionalParamsValidator

    validates :names, array: true, allow_nil: true
    validates :guids, array: true, allow_nil: true
    validates :organization_guids, array: true, allow_nil: true
    validates :space_guids, array: true, allow_nil: true
    validates :page, integer: true, allow_nil: true, numericality: { greater_than: 0 }
    validates :per_page, integer: true, allow_nil: true, numericality: { greater_than: 0 }
    validates :order_by, string: true, allow_nil: true

    def initialize(params={})
      super(params.symbolize_keys)
    end

    def to_param_hash
      super(exclude: [:page, :per_page, :order_by])
    end

    def self.from_params(params)
      opts = params.dup
      ['names', 'guids', 'organization_guids', 'space_guids'].each do |attribute|
        to_array! opts, attribute
      end
      new(opts.symbolize_keys)
    end

    private

    def allowed_keys
      ALLOWED_KEYS
    end
  end
end
