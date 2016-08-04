module CloudController
  module Presenters
    module V2
      class AppPresenter < BasePresenter
        extend PresenterProvider

        present_for_class 'VCAP::CloudController::App'

        def entity_hash(controller, app, opts, depth, parents, orphans=nil)
          entity = {
            'name'                        => app.name,
            'space_guid'                  => app.space.guid,
            'stack_guid'                  => app.stack.guid,
            'buildpack'                   => app.buildpack.try(:url),
            'detected_buildpack'          => app.detected_buildpack,
            'detected_buildpack_guid'     => app.detected_buildpack_guid,
            'environment_json'            => redact(app, app.environment_json),
            'memory'                      => app.memory,
            'instances'                   => app.instances,
            'disk_quota'                  => app.disk_quota,
            'state'                       => app.state,
            'version'                     => app.version,
            'command'                     => app.command,
            'staging_task_id'             => app.staging_task_id,
            'package_state'               => app.package_state,
            'health_check_type'           => app.health_check_type,
            'health_check_timeout'        => app.health_check_timeout,
            'staging_failed_reason'       => app.staging_failed_reason,
            'staging_failed_description'  => app.staging_failed_description,
            'diego'                       => app.diego,
            'docker_image'                => app.docker_image,
            'package_updated_at'          => app.package_updated_at,
            'detected_start_command'      => app.detected_start_command,
            'enable_ssh'                  => app.enable_ssh,
            'docker_credentials_json'     => redact(app, app.docker_credentials_json),
            'ports'                       => app.ports,
            'console'                     => app.console,
            'debug'                       => app.debug,
            'production'                  => app.production,
          }

          entity.merge!(RelationsPresenter.new.to_hash(controller, app, opts, depth, parents, orphans))

          entity
        end

        private

        def redact(app, attr)
          if VCAP::CloudController::SecurityContext.admin? || app.space.has_developer?(VCAP::CloudController::SecurityContext.current_user)
            attr
          else
            { 'redacted_message' => '[PRIVATE DATA HIDDEN]' }
          end
        end
      end
    end
  end
end
