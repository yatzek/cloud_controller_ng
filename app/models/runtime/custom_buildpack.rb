module VCAP::CloudController
  class CustomBuildpack < Struct.new(:url)
    def to_s
      url
    end

    def to_json
      MultiJson.dump(url)
    end

    def valid?
      errors << error_message unless url_valid?
      errors.empty?
    rescue Addressable::URI::InvalidURIError
      errors << error_message
      errors.empty?
    end


    def errors
      @errors ||= []
    end

    def staging_message
      {
        buildpack: url,
        buildpack_git_url: url
      }
    end

    def custom?
      true
    end

    private

    def url_valid?
      url =~ URI_REGEXP && Addressable::URI.parse(url)
    end

    def error_message
      "#{url} is not valid public url or a known buildpack name"
    end
  end
end
