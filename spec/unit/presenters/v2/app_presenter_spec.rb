require 'spec_helper'

module CloudController::Presenters::V2
  RSpec.describe AppPresenter do
    subject { described_class.new }

    before do
      space.organization.add_user(user)
      set_current_user(user)
      allow(RelationsPresenter).to receive(:new).and_return(relations_presenter)
    end

    let(:opts) { {} }
    let(:depth) { 'depth' }
    let(:parents) { 'parents' }
    let(:orphans) { 'orphans' }
    let(:controller) { 'controller' }
    let(:relations_presenter) { instance_double(RelationsPresenter, to_hash: relations_hash) }
    let(:relations_hash) { { 'relationship_key' => 'relationship_value' } }

    let(:user) { VCAP::CloudController::User.make }
    let(:space) { VCAP::CloudController::Space.make }
    let(:app) { VCAP::CloudController::AppFactory.make(space: space, docker_credentials_json: docker_creds) }
    let(:detected_buildpack) { VCAP::CloudController::Buildpack.make }
    let(:docker_creds) { { 'docker_user' => 'youdontknowme', 'docker_password' => 'password', 'docker_email' => 'blah@blah.com' } }

    describe '#entity_hash' do
      before do
        space.add_developer(user)
        app.buildpack = detected_buildpack.name
        app.update_detected_buildpack('detect me', detected_buildpack.key)
      end

      it 'returns all the information on app' do
         expect(subject.entity_hash(controller, app, opts, depth, parents, orphans)).to eq(
          {
            'name'                        => app.name,
            'space_guid'                  => space.guid,
            'stack_guid'                  => app.stack.guid,
            'buildpack'                   => detected_buildpack,
            'detected_buildpack'          => 'detect me',
            'detected_buildpack_guid'     => detected_buildpack.guid,
            'environment_json'            => nil,
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
            'staging_failed_description'  => nil,
            'diego'                       => false,
            'docker_image'                => nil,
            'package_updated_at'          => app.package_updated_at,
            'detected_start_command'      => app.detected_start_command,
            'enable_ssh'                  => app.enable_ssh,
            'docker_credentials_json'     => { 'docker_user' => 'youdontknowme', 'docker_password' => 'password', 'docker_email' => 'blah@blah.com' },
            'ports'                       => nil,
            'console'                     => app.console,
            'debug'                       => app.debug,
            'production'                  => app.production,
            'relationship_key'            => 'relationship_value'
          }
        )

        expect(relations_presenter).to have_received(:to_hash).with(controller, app, opts, depth, parents, orphans)
      end
    end

    describe '#redact' do
      context 'when the user does not have access to private information' do
        before do
          space.organization.add_user(user)
          space.add_auditor(user)
        end
        it 'removes private data' do
          expect(subject.entity_hash(controller, app, opts, depth, parents, orphans)).to include(
            {
              'environment_json'          => {'redacted_message' => '[PRIVATE DATA HIDDEN]'},
              'docker_credentials_json'   => {'redacted_message' => '[PRIVATE DATA HIDDEN]'}
            }
          )
        end
      end
    end
  end
end
