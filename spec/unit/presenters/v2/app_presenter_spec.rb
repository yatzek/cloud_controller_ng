require 'spec_helper'

module CloudController::Presenters::V2
  RSpec.describe AppPresenter do
    let(:app_presenter) { described_class.new }
    let(:controller) { 'controller' }
    let(:opts) { {} }
    let(:depth) { 'depth' }
    let(:parents) { 'parents' }
    let(:orphans) { 'orphans' }
    let(:relations_presenter) { instance_double(RelationsPresenter, to_hash: relations_hash) }
    let(:relations_hash) { { 'relationship_key' => 'relationship_value' } }

    describe '#entity_hash' do
      before do
        allow(RelationsPresenter).to receive(:new).and_return(relations_presenter)
      end

      let(:space) { VCAP::CloudController::Space.make }
      let(:stack) { VCAP::CloudController::Stack.make }
      let(:app) do
        VCAP::CloudController::AppFactory.make(name: 'utako',
                                               space: space,
                                               stack: stack,
                                               buildpack: 'https://github.com/custombuildpack',
                                               memory: 1024,
                                               disk_quota: 1024,
                                               state: 'STOPPED',
                                               command: 'start'
                                              )
      end

      it 'returns the app entity and associated urls' do
        expected_entity_hash = {
          'name'                        => 'utako',
          'space_guid'                  => space.guid,
          'stack_guid'                  => stack.guid,
          'buildpack'                   => 'https://github.com/custombuildpack',
          'detected_buildpack'          => nil,
          'detected_buildpack_guid'     => nil,
          'environment_json'            => {'redacted_message'=>'[PRIVATE DATA HIDDEN]'},
          'memory'                      => 1024,
          'instances'                   => 1,
          'disk_quota'                  => 1024,
          'state'                       => 'STOPPED',
          'version'                     => app.version,
          'command'                     => 'start',
          'staging_task_id'             => nil,
          'package_state'               => 'PENDING',
          'health_check_type'           => 'port',
          'health_check_timeout'        => nil,
          'staging_failed_reason'       => anything,
          'staging_failed_description'  => anything,
          'diego'                       => anything,
          'docker_image'                => anything,
          'package_updated_at'          => anything,
          'detected_start_command'      => anything,
          'enable_ssh'                  => anything,
          'docker_credentials_json'     => anything,
          'ports'                       => nil,
          'console'                     => anything,
          'debug'                       => anything,
          'production'                  => anything,
        }

        actual_entity_hash = app_presenter.entity_hash(controller, app, opts, depth, parents, orphans)

        expect(actual_entity_hash).to eq expected_entity_hash
        expect(relations_presenter).to have_received(:to_hash).with(controller, route, opts, depth, parents, orphans)
      end
    end
  end
end
