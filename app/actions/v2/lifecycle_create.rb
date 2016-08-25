module VCAP::CloudController
  module V2
    class LifecycleCreate

      def initialize(user, user_email)
        @user       = user
        @user_email = user_email
      end

      def create(attrs, app)
        buildpack_type_requested = attrs.key?('buildpack') || attrs.key?('stack_guid')

        if buildpack_type_requested || !attrs.key?('docker_image')
          stack = Stack.default unless Stack.find(guid: attrs['stack_guid'])
          app.buildpack_lifecycle_data = BuildpackLifecycleDataModel.new(
            buildpack: attrs['buildpack'],
            stack:     stack.try(:name),
          )
          app.save
        end

        if attrs.key?('docker_image')
          create_message = PackageCreateMessage.new({ type: 'docker', app_guid: app.guid, data: { image: attrs['docker_image'] } })
          creator        = PackageCreate.new(@user, @user_email)
          creator.create(create_message)
        end
      end
    end
  end
end
