require 'sinatra'

class FooBase
  def self.get(*args, &blk)
    VCAP::CloudController::FrontController.send(:get, *args, &blk)
  end

  def self.post(*args, &blk)
    VCAP::CloudController::FrontController.send(:post, *args, &blk)
  end

  def self.put(*args, &blk)
    VCAP::CloudController::FrontController.send(:put, *args, &blk)
  end
end

class FooController < Sinatra::Base
  get '/' do
    '{"text":"Hello world"}'
  end

  post '/' do
    # validate the parameters using the v2 app controller implementation

    v3_app = VCAP::CloudController::AppModel.new(
      name: params["name"],
      space_guid: params["space_guid"]
    ).save

    process = VCAP::CloudController::ProcessModel.create(
      name: params["name"],
      space_guid: params["space_guid"],
      app: v3_app,
      docker_credentials_json: params["docker_credentials_json"]
    )

    # create a v3 app
    # create a v2 app
      record_app_create_value = @app_event_repository.record_app_create(
        app,
        app.space,
        SecurityContext.current_user.guid,
        SecurityContext.current_user_email,
        request_attrs)

    presenters_response = {
      'metadata' => {
        'guid'       => process.guid,
        'url'        => "/v2/apps/#{process.guid}",
        'created_at' => process.created_at,
        'updated_at' => process.updated_at
      },
      'entity' => {
        'name'                       => process.app.name,
        'production'                 => false,
        'space_guid'                 => process.space.guid,
        'stack_guid'                 => process.stack.guid,
        'buildpack'                  => nil,
        'detected_buildpack'         => process.detected_buildpack,
        'environment_json'           => process.app.environment_variables,
        'memory'                     => 1024,
        'instances'                  => 1,
        'disk_quota'                 => 1024,
        'state'                      => process.app.desired_state,
        'version'                    => process.version,
        'command'                    => nil,
        'console'                    => false,
        'debug'                      => nil,
        'staging_task_id'            => nil,
        'package_state'              => 'PENDING',
        'health_check_type'          => 'port',
        'health_check_timeout'       => nil,
        'staging_failed_reason'      => nil,
        'staging_failed_description' => nil,
        'diego'                      => false,
        'docker_image'               => nil,
        'package_updated_at'         => nil,
        'detected_start_command'     => '',
        'enable_ssh'                 => true,
        'docker_credentials_json'    => process.docker_credentials_json,
        'ports'                      => nil,
        'space_url'                  => "/v2/spaces/#{process.space.guid}",
        'stack_url'                  => "/v2/stacks/#{process.stack.guid}",
        'routes_url'                 => "/v2/apps/#{process.guid}/routes",
        'events_url'                 => "/v2/apps/#{process.guid}/events",
        'service_bindings_url'       => "/v2/apps/#{process.guid}/service_bindings",
        'route_mappings_url'         => "/v2/apps/#{process.guid}/route_mappings"
      }
    }
    # create a presenter that returns hash in a v2 api format
    [201, presenters_response.to_json]
  end
end

class FooRouter
  def initialize(builder)
    @builder = builder
  end

  def map(route, controller, *args)
    @builder.instance_eval do
      map route do
        run controller.new(*args)
      end
    end
  end
end

class BarRouter
  def self.map_routes(builder, config)
    builder.instance_eval do
      map '/' do
        run VCAP::CloudController::FrontController.new(config)
      end

      map '/v2/apps' do
        run FooController.new
      end
    end
  end
end
