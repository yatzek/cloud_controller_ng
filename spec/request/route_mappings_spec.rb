require 'spec_helper'

describe 'Route Mappings' do
  let(:space) { Space.make }
  let(:app_model) { AppModel.make(space: space) }
  let(:process) { App.make(:process, space: space, app: app_model, type: 'worker', ports: [8888]) }
  let(:route) { Route.make(space: space) }
  let(:developer) { make_developer_for_space(space) }
  let(:developer_headers) do
    headers_for(developer)
  end

  before do
    allow(ApplicationController).to receive(:configuration).and_return(TestConfig.config)
  end

  describe 'POST /v3/route_mappings' do
    it 'creates a route mapping for a specific process on an app on a specific port' do
      body = {
        app_port:      8888,
        relationships: {
          app:     { guid: app_model.guid },
          route:   { guid: route.guid },
          process: { type: process.type }
        }
      }

      post '/v3/route_mappings', body, developer_headers

      route_mapping = RouteMappingModel.last

      expected_response = {
        'guid'       => route_mapping.guid,
        'app_port'   => 8888,
        'created_at' => iso8601,
        'updated_at' => nil,

        'links'      => {
          'self'    => { 'href' => "/v3/route_mappings/#{route_mapping.guid}" },
          'app'     => { 'href' => "/v3/apps/#{app_model.guid}" },
          'route'   => { 'href' => "/v2/routes/#{route.guid}" },
          'process' => { 'href' => "/v3/apps/#{app_model.guid}/processes/worker" }
        }
      }

      parsed_response = MultiJson.load(last_response.body)

      # verify response
      expect(last_response.status).to eq(201)
      expect(parsed_response).to be_a_response_like(expected_response)

      # verify mapping
      expect(app_model.routes).to eq([route])
      expect(process.reload.routes).to eq([route])
      expect(route_mapping.app_guid).to eq(app_model.guid)
      expect(route_mapping.route_guid).to eq(route.guid)
      expect(route_mapping.process_type).to eq('worker')
      expect(route_mapping.app_port).to eq(8888)

      # verify audit event
      event = Event.last
      expect(event.values).to include({
        type:              'audit.app.map-route',
        actee:             app_model.guid,
        actee_type:        'v3-app',
        actee_name:        app_model.name,
        actor:             developer.guid,
        actor_type:        'user',
        space_guid:        space.guid,
        metadata:          {
                             route_guid:         route.guid,
                             app_port:           8888,
                             route_mapping_guid: route_mapping.guid,
                             process_type:       'worker'
                           }.to_json,
        organization_guid: space.organization.guid,
      })
    end
  end

  describe 'GET /v3/route_mappings' do
    let!(:route_mapping1) { RouteMappingModel.make(app: app_model, route: route) }
    let!(:route_mapping2) { RouteMappingModel.make(app: app_model, route: route, process_type: 'worker') }
    let!(:route_mapping3) { RouteMappingModel.make(app: app_model, route: route, process_type: 'other') }
    let!(:route_mapping4) { RouteMappingModel.make }

    it 'retrieves all the route mappings the user has access to' do
      get '/v3/route_mappings?per_page=2', nil, developer_headers

      expected_response = {
        'pagination' => {
          'total_results' => 3,
          'total_pages'   => 2,
          'first'         => { 'href' => '/v3/route_mappings?page=1&per_page=2' },
          'last'          => { 'href' => '/v3/route_mappings?page=2&per_page=2' },
          'next'          => { 'href' => '/v3/route_mappings?page=2&per_page=2' },
          'previous'      => nil
        },
        'resources' => [
          {
            'guid'       => route_mapping1.guid,
            'app_port'   => 8080,
            'created_at' => iso8601,
            'updated_at' => nil,

            'links'      => {
              'self'    => { 'href' => "/v3/route_mappings/#{route_mapping1.guid}" },
              'app'     => { 'href' => "/v3/apps/#{app_model.guid}" },
              'route'   => { 'href' => "/v2/routes/#{route.guid}" },
              'process' => { 'href' => "/v3/apps/#{app_model.guid}/processes/web" }
            }
          },
          {
            'guid'       => route_mapping2.guid,
            'app_port'   => 8080,
            'created_at' => iso8601,
            'updated_at' => nil,

            'links'      => {
              'self'    => { 'href' => "/v3/route_mappings/#{route_mapping2.guid}" },
              'app'     => { 'href' => "/v3/apps/#{app_model.guid}" },
              'route'   => { 'href' => "/v2/routes/#{route.guid}" },
              'process' => { 'href' => "/v3/apps/#{app_model.guid}/processes/worker" }
            }
          }
        ]
      }

      parsed_response = MultiJson.load(last_response.body)

      # verify response
      expect(last_response.status).to eq(200)
      expect(parsed_response).to be_a_response_like(expected_response)
    end

    context 'faceted list' do
      context 'by app_guids' do
        let(:app_model2) { AppModel.make(space: space) }
        let!(:route_mapping5) { RouteMappingModel.make(app: app_model2, route: route, process_type: 'other') }

        it 'returns only the matching route mappings' do
          get "/v3/route_mappings?app_guids=#{app_model.guid},#{app_model2.guid}", nil, developer_headers

          expected_pagination = {
            'total_results' => 4,
            'total_pages'   => 1,
            'first'         => { 'href' => "/v3/route_mappings?app_guids=#{app_model.guid}%2C#{app_model2.guid}&page=1&per_page=50" },
            'last'          => { 'href' => "/v3/route_mappings?app_guids=#{app_model.guid}%2C#{app_model2.guid}&page=1&per_page=50" },
            'next'          => nil,
            'previous'      => nil
          }
          expected_guids = [route_mapping1.guid, route_mapping2.guid, route_mapping3.guid, route_mapping5.guid]

          parsed_response = MultiJson.load(last_response.body)
          returned_guids  = parsed_response['resources'].map { |i| i['guid'] }

          expect(last_response.status).to eq(200)
          expect(parsed_response['pagination']).to be_a_response_like(expected_pagination)
          expect(returned_guids).to match_array(expected_guids)
        end
      end

      context 'by route_guids' do
        let(:route2) { Route.make(space: space) }
        let!(:route_mapping5) { RouteMappingModel.make(app: app_model, route: route2, process_type: 'other') }

        it 'returns only the matching route mappings' do
          get "/v3/route_mappings?route_guids=#{route.guid},#{route2.guid}", nil, developer_headers

          expected_pagination = {
            'total_results' => 4,
            'total_pages'   => 1,
            'first'         => { 'href' => "/v3/route_mappings?page=1&per_page=50&route_guids=#{route.guid}%2C#{route2.guid}" },
            'last'          => { 'href' => "/v3/route_mappings?page=1&per_page=50&route_guids=#{route.guid}%2C#{route2.guid}" },
            'next'          => nil,
            'previous'      => nil
          }
          expected_guids = [route_mapping1.guid, route_mapping2.guid, route_mapping3.guid, route_mapping5.guid]

          parsed_response = MultiJson.load(last_response.body)

          expect(last_response.status).to eq(200)
          returned_guids = parsed_response['resources'].map { |i| i['guid'] }
          expect(parsed_response['pagination']).to be_a_response_like(expected_pagination)
          expect(returned_guids).to match_array(expected_guids)
        end
      end
    end
  end

  describe 'GET /v3/route_mappings/:route_mapping_guid' do
    let(:route_mapping) { RouteMappingModel.make(app: app_model, route: route, process_type: 'worker') }

    it 'retrieves the requests route mapping' do
      get "/v3/route_mappings/#{route_mapping.guid}", nil, developer_headers

      expected_response = {
        'guid'       => route_mapping.guid,
        'app_port'   => 8080,
        'created_at' => iso8601,
        'updated_at' => nil,

        'links'      => {
          'self'    => { 'href' => "/v3/route_mappings/#{route_mapping.guid}" },
          'app'     => { 'href' => "/v3/apps/#{app_model.guid}" },
          'route'   => { 'href' => "/v2/routes/#{route.guid}" },
          'process' => { 'href' => "/v3/apps/#{app_model.guid}/processes/#{process.type}" }
        }
      }

      parsed_response = MultiJson.load(last_response.body)

      # verify response
      expect(last_response.status).to eq(200)
      expect(parsed_response).to be_a_response_like(expected_response)
    end
  end

  describe 'DELETE /v3/route_mappings/:route_mapping_guid' do
    let!(:route_mapping) { RouteMappingModel.make(app: app_model, route: route, process_type: 'buckeyes') }

    it 'deletes the specified route mapping' do
      delete "/v3/route_mappings/#{route_mapping.guid}", nil, developer_headers

      # verify response
      expect(last_response.status).to eq(204)
      expect(route_mapping.exists?).to be_falsey

      # verify audit event
      event = Event.last
      expect(event.values).to include({
        type:              'audit.app.unmap-route',
        actee:             app_model.guid,
        actee_type:        'v3-app',
        actee_name:        app_model.name,
        actor:             developer.guid,
        actor_type:        'user',
        space_guid:        space.guid,
        metadata:          {
                             route_guid:         route.guid,
                             route_mapping_guid: route_mapping.guid,
                             process_type:       'buckeyes'
                           }.to_json,
        organization_guid: space.organization.guid,
      })
    end
  end

  describe 'GET /v3/apps/:guid/route_mappings' do
    let!(:route_mapping1) { RouteMappingModel.make(app: app_model, route: route) }
    let!(:route_mapping2) { RouteMappingModel.make(app: app_model, route: route, process_type: 'worker') }
    let!(:route_mapping3) { RouteMappingModel.make(app: app_model, route: route, process_type: 'other') }

    it 'retrieves all the route mappings associated with the given app' do
      get "/v3/apps/#{app_model.guid}/route_mappings?per_page=2", nil, developer_headers

      expected_response = {
        'pagination' => {
          'total_results' => 3,
          'total_pages'   => 2,
          'first'         => { 'href' => "/v3/apps/#{app_model.guid}/route_mappings?page=1&per_page=2" },
          'last'          => { 'href' => "/v3/apps/#{app_model.guid}/route_mappings?page=2&per_page=2" },
          'next'          => { 'href' => "/v3/apps/#{app_model.guid}/route_mappings?page=2&per_page=2" },
          'previous'      => nil
        },
        'resources' => [
          {
            'guid'       => route_mapping1.guid,
            'app_port'   => 8080,
            'created_at' => iso8601,
            'updated_at' => nil,

            'links'      => {
              'self'    => { 'href' => "/v3/route_mappings/#{route_mapping1.guid}" },
              'app'     => { 'href' => "/v3/apps/#{app_model.guid}" },
              'route'   => { 'href' => "/v2/routes/#{route.guid}" },
              'process' => { 'href' => "/v3/apps/#{app_model.guid}/processes/web" }
            }
          },
          {
            'guid'       => route_mapping2.guid,
            'app_port'   => 8080,
            'created_at' => iso8601,
            'updated_at' => nil,

            'links'      => {
              'self'    => { 'href' => "/v3/route_mappings/#{route_mapping2.guid}" },
              'app'     => { 'href' => "/v3/apps/#{app_model.guid}" },
              'route'   => { 'href' => "/v2/routes/#{route.guid}" },
              'process' => { 'href' => "/v3/apps/#{app_model.guid}/processes/worker" }
            }
          }
        ]
      }

      parsed_response = MultiJson.load(last_response.body)

      # verify response
      expect(last_response.status).to eq(200)
      expect(parsed_response).to be_a_response_like(expected_response)
    end

    context 'faceted list' do
      context 'by route_guids' do
        let(:route2) { Route.make(space: space) }
        let!(:route_mapping4) { RouteMappingModel.make(app: app_model, process_type: 'other') }
        let!(:route_mapping5) { RouteMappingModel.make(app: app_model, route: route2, process_type: 'other') }

        it 'returns only the matching route mappings' do
          get "/v3/apps/#{app_model.guid}/route_mappings?route_guids=#{route.guid},#{route2.guid}", nil, developer_headers

          expected_pagination = {
            'total_results' => 4,
            'total_pages'   => 1,
            'first'         => { 'href' => "/v3/apps/#{app_model.guid}/route_mappings?page=1&per_page=50&route_guids=#{route.guid}%2C#{route2.guid}" },
            'last'          => { 'href' => "/v3/apps/#{app_model.guid}/route_mappings?page=1&per_page=50&route_guids=#{route.guid}%2C#{route2.guid}" },
            'next'          => nil,
            'previous'      => nil
          }
          expected_guids = [route_mapping1.guid, route_mapping2.guid, route_mapping3.guid, route_mapping5.guid]

          parsed_response = MultiJson.load(last_response.body)

          expect(last_response.status).to eq(200)
          returned_guids = parsed_response['resources'].map { |i| i['guid'] }
          expect(parsed_response['pagination']).to be_a_response_like(expected_pagination)
          expect(returned_guids).to match_array(expected_guids)
        end
      end
    end
  end
end
