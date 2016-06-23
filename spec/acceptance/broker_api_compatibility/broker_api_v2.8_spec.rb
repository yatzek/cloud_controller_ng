require 'spec_helper'

RSpec.describe 'Service Broker API integration' do
  describe 'v2.8' do
    include VCAP::CloudController::BrokerApiHelper
      let(:route) { VCAP::CloudController::Route.make(space: @space) }
      let(:catalog) { default_catalog(requires: ['route_forwarding']) }
      let(:binding_request) { %r{ /v2/service_instances/#{@service_instance_guid}/service_bindings/#{guid_pattern} } }
      let(:request_body) { { bind_resource: { route: route.uri } }.to_json  }

      before do
        setup_cc
        setup_broker(catalog)
        create_app
        provision_service
        bind_service
        bind_route_to_service_instance
      end

      after do
        delete_broker
      end

    describe 'route forwarding for service bindings' do
      it 'cc responds with success' do

        # √ set up broker
        # √ setup service instance
        # √ setup binding between instance and app
        # makes another service binding request, with the route being the bind resource

        stub_request(:put, binding_request).to_return(status: 201, body: {}.to_json)

        put("/v2/service_instances/#{@service_instance_guid}/routes/#{route.guid}", request_body, json_headers(admin_headers))
        expect(last_response.status).to eq 201

        get("/v2/service_instances/#{@service_instance_guid}/routes", {}, json_headers(admin_headers))
        expect(last_response.status).to eq 200
        expect(MultiJson.load(last_response.body)['total_results']).to eq(1)
      end

      # context 'when the broker returns a route service url' do
      #   # let(:service_broker_client) { instance_double(VCAP::Services::ServiceBrokers::V2::HttpClient, put: {'route_service_url' => 'www.neopets.com'}) }
      #
      #   it 'cc proxies the bind request' do
      #     # allow(service_broker_client).to receive(:put).with(anything, anything).and_return({'route_service_url' => 'www.neopets.com'})
      #
      #     # stub_request(:put, binding_request).to_return(status: 201, body: {'route_service_url' => 'www.neopets.com'}.to_json)
      #     put("/v2/service_instances/#{@service_instance_guid}/routes/#{route.guid}", request_body, json_headers(admin_headers))
      #     # expect(service_broker_client).to have_received(:put).with(anything, anything)
      #
      #     service_instance = VCAP::CloudController::ServiceInstance.find(guid: @service_instance_guid)
      #
      #     expect(last_response.status).to eq 201
      #     expect(service_instance.route_service_url).to eq('www.neopets.com')
      #   end
      # end
    end
  end
end

# cc user /v2/service_instances/:service_instance_guid/routes/:route_guid

# cc proxys over to sb v2/service_instances/#{service_instance.guid}/service_bindings/:service_binding_guid
