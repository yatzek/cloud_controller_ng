module VCAP::CloudController::ResourcePool
  class BitsServicePool
    def initialize(endpoint)
      @endpoint = URI.parse(endpoint)
    end

    def match_resources(descriptors)
      resources_json = JSON.generate(descriptors)

      response = post('/app_stash/matches', resources_json).tap do |response|
        validate_response_code!(200, response)
      end

      JSON.parse(response.body)
    end

    def add_resources(zip_filepath)
      with_file_attachment!(zip_filepath, 'entries.zip') do |file_attachment|
        body = { application: file_attachment }
        multipart_post('/app_stash/entries', body)
      end
    end

    def get_package(descriptors)
      resources_json = JSON.generate(descriptors)

      response = post('/app_stash/bundles', resources_json).tap do |response|
        validate_response_code!(200, response)
      end

      response.body
    end

    private

    def validate_response_code!(expected, response)
      return if expected.to_i == response.code.to_i

      error = {
        response_code: response.code,
        response_body: response.body,
        response: response
      }.to_json

      logger.error("UnexpectedResponseCode: expected #{expected} got #{error}")

      fail error
    end

    def with_file_attachment!(file_path, filename, &block)
      validate_file! file_path

      File.open(file_path) do |file|
        attached_file = UploadIO.new(file, 'application/octet-stream', filename)
        yield attached_file
      end
    end

    def validate_file!(file_path)
      return if File.exist?(file_path)

      fail "Could not find file: #{file_path}"
    end

    def post(path, body, header={})
      request = Net::HTTP::Post.new(path, header)

      request.body = body
      do_request(http_client, request)
    end

    def multipart_post(path, body, header={})
      request = Net::HTTP::Post::Multipart.new(path, body, header)
      do_request(http_client, request).tap do |response|
        validate_response_code!(201, response)
      end
    end

    def do_request(http_client, request)
      request_id = SecureRandom.uuid

      logger.info('Request', {
        method: request.method,
        path: request.path,
        address: http_client.address,
        port: http_client.port,
        vcap_id: VCAP::Request.current_id,
        request_id: request_id
      })

      request.add_field(VCAP::Request::HEADER_NAME, VCAP::Request.current_id)

      http_client.request(request).tap do |response|
        logger.info('Response', { code: response.code, vcap_id: VCAP::Request.current_id, request_id: request_id })
      end
    end

    def http_client
      @http_client ||= Net::HTTP.new(@endpoint.host, @endpoint.port)
    end

    def private_endpoint
      URI.parse('http://bits-service.service.cf.internal/')
    end

    def logger
      @logger ||= Steno.logger('cc.bits_service_pool')
    end
  end
end
