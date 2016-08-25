module VCAP::CloudController
  module V2
    class LifecycleCreate
      def initialize(user_guid, user_email)
        @user_guid = user_guid
        @user_email = user_email
      end

      def create(attrs, app)
        buildpack_type_requested = attrs.key?('buildpack') || attrs.key?('stack_guid')
        docker_type_requested = attrs.key?('docker_image')

        if docker_type_requested
          create_message = PackageCreateMessage.new({ type: 'docker', app_guid: app.guid, data: { image: attrs['docker_image'] } })
          PackageCreate.new(@user_guid, @user_email).create(create_message)
        elsif buildpack_type_requested || !docker_type_requested
          app.buildpack_lifecycle_data = BuildpackLifecycleDataModel.new(
            buildpack: attrs['buildpack'],
            stack:     get_stack_name(attrs['stack_guid']),
          )
          app.save
        end
      end

      private

      def get_stack_name(stack_guid)
        stack = Stack.find(guid: stack_guid)
        stack_name = stack.present? ? stack.name : Stack.default.name
        stack_name
      end
    end
  end
end
