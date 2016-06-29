require_relative 'bits_service_client'

module CloudController
  module Blobstore
    module BitsService
      class UrlSigner
        def initialize(http_client:, username:, password:)
          @client   = http_client
          @username = username
          @password = password
        end

        def sign(expires:, url:)
          original_uri = URI(url)

          request_uri  = uri(expires: expires, path: original_uri.path)
          response_uri = make_request(uri: request_uri)

          original_uri.path   = response_uri.path
          original_uri.query  = response_uri.query
          original_uri.to_s
        end

        private

        def headers
          { 'Authorization' => 'Basic ' + Base64.strict_encode64("#{@username}:#{@password}").strip }
        end

        def make_request(uri:)
          response = @client.get(uri, headers)

          raise SigningRequestError.new("Could not get a signed url, #{response.code}/#{response.body}") unless response.code.to_i == 200

          URI(response.body)
        rescue OpenSSL::SSL::SSLError => e
          err = SigningRequestError.new("Could not get a signed url: #{e.message}")
          err.set_backtrace(e.backtrace)
          raise err
        end

        def uri(expires:, path:)
          uri       = URI(@client.address)
          uri.path  = '/sign'
          uri.query = {
            expires: expires,
            path:    File.join(['/', path])
          }.to_query

          uri.to_s
        end
      end
    end
  end
end
