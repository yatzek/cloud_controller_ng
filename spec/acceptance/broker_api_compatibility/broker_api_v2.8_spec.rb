require 'spec_helper'

RSpec.describe 'Service Broker API integration' do
  let(:user) { VCAP::CloudController::User.make }
  let(:space) { VCAP::CloudController::Space.make }

  before do
    space.organization.add_user(user)
    space.add_developer(user)
  end

  describe 'v2.8' do
    include VCAP::CloudController::BrokerApiHelper
    describe 'max port limit' do
      let(:post_params) {
        MultiJson.dump({
          name: 'maria',
          space_guid: space.guid,
          detected_start_command: 'echo meow',
          diego: true,
          ports: ports
        })
      }
      context 'with 10 or fewer ports' do
        let(:ports) { [8080, 8081, 8082, 8083, 8084, 8085, 8086, 8087, 8088, 8089] }
        it 'creates an app ' do
          post '/v2/apps', post_params, headers_for(user)
          expect(last_response.status).to eq(201)
        end
      end
      context 'with 11 or more ports' do
        let(:ports) { [8080, 8081, 8082, 8083, 8084, 8085, 8086, 8087, 8088, 8089, 8090] }
        it 'raises an error' do
          post '/v2/apps', post_params, headers_for(user)
          expect(last_response.status).to eq(400)
          expect(last_response.body).to match('The app is invalid: ports Maximum of 10 app ports allowed.')
        end
      end
    end

    describe 'tag limit' do
      let(:space) { VCAP::CloudController::Space.make }
      let(:service_plan) { VCAP::CloudController::ServicePlan.make }
      let(:request_attrs) do
        MultiJson.dump({
          'space_guid' => space.guid,
          'service_plan_guid' => service_plan.guid,
          'name' => 'my-instance',
          'tags' => tags
        })
      end

      before do
        stub_provision(service_plan.service.service_broker, body: {}.to_json)
      end

      context 'with a tag 2048 characters or less' do
        let(:tags) { ['normal-tag'] }
        it 'creates a service instance' do
          post '/v2/service_instances?accepts_incomplete=true', request_attrs, headers_for(user)
          expect(last_response.status).to eq(201)
          expect(VCAP::CloudController::ServiceInstance.last.tags).to eq(['normal-tag'])
        end
      end
      context 'with a tag 2049 characters or more' do
        let(:tags) { ['*'*2049] }
        it 'creates a service instance' do
          post '/v2/service_instances?accepts_incomplete=true', request_attrs, headers_for(user)
          expect(last_response.status).to eq(400)
          expect(last_response.body).to match('Combined length of tags for service my-instance must be 2048 characters or less.')
        end
      end
    end

    describe 'route forwarding' do
      let(:service) { VCAP::CloudController::Service.make(requires: requires) }
      let(:service_plan) { VCAP::CloudController::ServicePlan.make(service: service) }
      let(:service_instance) do
        VCAP::CloudController::ManagedServiceInstance.make(
          service_plan: service_plan,
          name: 'meow'
        )
      end
      context 'service that does require route_forwarding' do
        let(:requires) { ['route_forwarding'] }

        it 'should allow service_binding with route_forwarding???' do
          expect {
            service_binding = VCAP::CloudController::ServiceBinding.make(service_instance: service_instance)
            service_binding.route_forwarding = nil
            service_binding.save
          }.not_to raise_error
        end
      end
    end
  end
end



