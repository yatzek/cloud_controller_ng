module CloudController
  module Blobstore
    class BitsServiceBlob
      attr_reader :guid

      def initialize(guid:, public_url:, internal_url:, signer:)
        @guid = guid
        @public_url = public_url
        @internal_url = internal_url
        @signer = signer
      end

      def public_download_url
        sign_url(@public_url)
      end

      def internal_download_url
        sign_url(@internal_url)
      end

      def attributes(*_)
        []
      end

      private

      def sign_url(url)
        return url unless URI(url).host =~ /^bits-service\./
        @signer.sign(expires: Time.now.utc.to_i + 3600, url: url)
      end
    end
  end
end
