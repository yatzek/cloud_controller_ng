require 'cloud_controller/blobstore/blob'

module CloudController
  module Blobstore
    class Client
      extend Forwardable

      attr_reader :wrapped_client

      def initialize(client)
        @wrapped_client = client
      end

      def_delegators :@wrapped_client,
      :local?,
      :exists?,
      :download_from_blobstore,
      :cp_to_blobstore,
      :cp_r_to_blobstore,
      :cp_file_between_keys,
      :delete_all,
      :delete_all_in_path,
      :delete,
      :delete_blob,
      :download_uri,
      :blob

      def sign_url(arg)
        logger.info("Delegating to #{@wrapped_client.class} methods: #{@wrapped_client.public_methods - Object.public_instance_methods}")

        @wrapped_client.sign_url(arg)
      end

      def logger
        @logger ||= Steno.logger('cc.XXX')
      end
    end
  end
end
