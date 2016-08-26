module VCAP::CloudController
  module V2
    class LifecycleUpdate
      def initialize(user_guid, user_email)
        @user_guid  = user_guid
        @user_email = user_email
      end

      def update(attrs, app)
        v3_app = app.app

        buildpack_type_requested = attrs.key?('buildpack') || attrs.key?('stack_guid')

        if buildpack_type_requested
          v3_app.lifecycle_data.buildpack = attrs['buildpack'] if attrs.key?('buildpack')

          if attrs.key?('stack_guid')
            v3_app.lifecycle_data.stack = Stack.find(guid: attrs['stack_guid']).try(:name)
            v3_app.update(droplet: nil)
            app.reload
          end
        elsif attrs.key?('docker_image') && !case_insensitive_equals(app.docker_image, attrs['docker_image'])
          create_message = PackageCreateMessage.new({ type: 'docker', app_guid: v3_app.guid, data: { image: attrs['docker_image'] } })
          creator        = PackageCreate.new(@user_guid, @user_email)
          creator.create(create_message)
        end
      end

      private

      def case_insensitive_equals(str1, str2)
        str1.casecmp(str2) == 0
      end
    end
  end
end
