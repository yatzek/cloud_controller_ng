require 'presenters/message_bus/service_binding_presenter'

module VCAP::CloudController
  module Dea
    class ServiceBindingClient
      def initialize()
        @client = HTTPClient.new
        @headers = { 'Authorization' => VCAP::CloudController::SecurityContext.auth_token }
      end

      def bindings_for_app(app_guid)

        result = @client.get("http://api.bosh-lite.com/v2/service_bindings?q=app_guid:#{app_guid}&inline-relations-depth=2", header: @headers)


        logger = Steno.logger('potato')
        logger.info("BINDING: status: #{result.status}  body: #{result.body}  ")


        json_body = MultiJson.load(result.body)

        json_body['resources'].map do |r|
          binding = OpenStruct.new
          instance = OpenStruct.new
          service_plan = OpenStruct.new
          service = OpenStruct.new

          entity =           r['entity']
          binding.credentials = entity['credentials']
          binding.binding_options = entity['binding_options']
          binding.syslog_drain_url = entity['syslog_drain_url']

          instance_entity = entity['service_instance']['entity']
          instance.is_gateway_service = true
          instance.name = instance_entity['name']
          instance.merged_tags = []

          plan_entity = instance_entity['service_plan']['entity']
          service_plan.name = plan_entity['name']

          service_url = plan_entity['service_url']
          service_result = @client.get("http://api.bosh-lite.com#{service_url}", header: @headers)
          service_json_body = MultiJson.load(service_result.body)

          logger.info("SERVICE: status: #{service_result.status}  service_result: #{result.body}  ")

          service_entity =service_json_body['entity']
          service.label = service_entity['label']
          service.provider = service_entity['provider']

          instance.service = service
          instance.service_plan = service_plan
          binding.service_instance = instance

          binding
        end
      end
    end


    class StartAppMessage < Hash
      def initialize(app, index, config, blobstore_url_generator)
        super()

        # Grab the v3 droplet if the app is a v3 process
        if app.app.nil?
          droplet_download_url = blobstore_url_generator.droplet_download_url(app)
          droplet_hash = app.droplet_hash
        else
          droplet = DropletModel.find(guid: app.app.droplet_guid)
          droplet_download_url = blobstore_url_generator.v3_droplet_download_url(droplet)
          droplet_hash = droplet.droplet_hash
        end

        self[:droplet]        = app.guid
        self[:name]           = app.name
        self[:stack]          = app.stack.name
        self[:uris]           = app.uris
        self[:prod]           = app.production
        self[:sha1]           = droplet_hash
        self[:executableFile] = 'deprecated'
        self[:executableUri]  = droplet_download_url
        self[:version]        = app.version

        client = ServiceBindingClient.new
        # self[:services] = app.service_bindings.map do |sb|
        self[:services] =client.bindings_for_app(app.guid).map do |sb|
          ServiceBindingPresenter.new(sb).to_hash
        end

        self[:limits] = {
            mem:  app.memory,
            disk: app.disk_quota,
            fds:  app.file_descriptors
        }

        staging_env = EnvironmentVariableGroup.running.environment_json
        app_env     = app.environment_json || {}
        env         = staging_env.merge(app_env).merge({ 'CF_PROCESS_TYPE' => app.type }).map { |k, v| "#{k}=#{v}" }
        self[:env]  = env

        self[:cc_partition]         = config[:cc_partition]
        self[:console]              = app.console
        self[:debug]                = app.debug
        self[:start_command]        = app.command
        self[:health_check_timeout] = app.health_check_timeout

        self[:vcap_application]     = VCAP::VarsBuilder.new(app).to_hash

        self[:index]                = index
        self[:egress_network_rules] = EgressNetworkRulesPresenter.new(app.space.security_groups).to_array
      end

      def has_app_package?
        !self[:executableUri].nil?
      end
    end
  end
end
