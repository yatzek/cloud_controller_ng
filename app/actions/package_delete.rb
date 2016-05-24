module VCAP::CloudController
  class PackageDelete
    def initialize(user_guid, user_email, bits_service_enabled=false)
      @user_guid = user_guid
      @user_email = user_email
      @bits_service_enabled = bits_service_enabled
    end

    def delete(packages)
      packages = Array(packages)

      packages.each do |package|
        blobstore_delete = Jobs::Runtime::BlobstoreDelete.new(key(package), :package_blobstore, nil)
        Jobs::Enqueuer.new(blobstore_delete, queue: 'cc-generic').enqueue
        package.destroy

        Repositories::PackageEventRepository.record_app_package_delete(
          package,
          @user_guid,
          @user_email)
      end
    end

    def key(package)
      @bits_service_enabled ? package.package_hash : package.guid
    end
  end
end
