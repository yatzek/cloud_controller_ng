class WebDAVClient
  class Mock
    def initialize
      @files = {}
    end

    def upload(url, file, options)
      p "uploading url #{url}"
      @files[url] = file
    end

    def exists?(url, options)
      p "checking existence of #{url}"
      @files.has_key? url
    end
  end

  def exists?(url, options)

  end
end
