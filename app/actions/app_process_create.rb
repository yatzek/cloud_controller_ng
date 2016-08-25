module VCAP::CloudController
  class AppProcessCreate
    def initialize(user_guid, user_email)
      @user_guid  = user_guid
      @user_email = user_email
    end

    def create(message)
      app = AppModel.create(
        name:                  message.name,
        space_guid:            message.space_guid,
        environment_variables: message.environment_json,
      )

      # lifecycle = AppLifecycleProvider.provide_for_create(message)
      # lifecycle.create_lifecycle_data_model(app)

      buildpack_type_requested = message.buildpack || message.stack_guid

      if buildpack_type_requested || !message.docker_image
        stack                        = message.stack_guid ? Stack.find(guid: message.stack_guid) : Stack.default
        app.buildpack_lifecycle_data = BuildpackLifecycleDataModel.new(
          buildpack: message.buildpack,
          stack:     stack.try(:name),
        )
        app.save
      end

      if message.docker_image
        create_message = PackageCreateMessage.new({ type: 'docker', app_guid: app.guid, data: { image: message.docker_image } })
        creator        = PackageCreate.new(@user_guid, @user_email)
        creator.create(create_message)
      end

      process = App.new(
        guid:                    app.guid,
        memory:                  message.memory,
        instances:               message.instances,
        disk_quota:              message.disk_quota,
        state:                   message.state,
        command:                 message.command,
        health_check_type:       message.health_check_type,
        health_check_timeout:    message.health_check_timeout,
        diego:                   message.diego,
        enable_ssh:              message.enable_ssh,
        docker_credentials_json: message.docker_credentials_json,
        ports:                   message.ports,
        route_guids:             message.route_guids,
        metadata:                {},
        app:                     app
      )

      process
    end
  end
end

