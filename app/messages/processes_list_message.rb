require 'messages/base_message'

module VCAP::CloudController
  class ProcessesListMessage < BaseMessage
    ALLOWED_KEYS = [:page, :per_page].freeze

    attr_accessor(*ALLOWED_KEYS)

    validates_with NoAdditionalParamsValidator

    validates :page, numericality: { greater_than: 0 }, allow_nil: true, integer: true
    validates :per_page, numericality: { greater_than: 0 }, allow_nil: true, integer: true

    def initialize(params={})
      super(params.symbolize_keys)
    end

    def self.from_params(params)
      opts = params.dup
      new(opts.symbolize_keys)
    end

    private

    def allowed_keys
      ALLOWED_KEYS
    end
  end
end
