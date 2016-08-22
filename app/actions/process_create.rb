require 'repositories/process_event_repository'

module VCAP::CloudController
  class ProcessCreate
    def initialize(user_guid, user_email)
      @user_guid  = user_guid
      @user_email = user_email
    end

    def create(app, message)
      attrs = message.merge({
        diego:             true,
        instances:         message[:type] == 'web' ? 1 : 0,
        health_check_type: message[:type] == 'web' ? 'port' : 'process',
        metadata:          {},
      })
      attrs[:guid] = app.guid if message[:type] == 'web'

      process = nil
      app.class.db.transaction do
        process = app.add_process(attrs)
        Repositories::ProcessEventRepository.record_create(process, @user_guid, @user_email)
      end

      process
    end

    def create_v2_process(app, message)
      process = nil

      App.db.transaction do
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

        Repositories::ProcessEventRepository.record_create(process, @user_guid, @user_email)
      end

      process
    end
  end
end
