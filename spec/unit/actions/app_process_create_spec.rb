require 'spec_helper'
require 'actions/app_process_create'
require 'messages/app_process_create_message'

module VCAP::CloudController
  RSpec.describe AppProcessCreate do
    let(:user_guid) { 'user-guid' }
    let(:user_email) { 'user@example.com' }
    let(:space) { Space.make }
    subject(:process_create) { described_class.new(user_guid, user_email) }
    let(:attrs) do
      {
        'name'                    => 'maria',
        'environment_json'        => { 'key' => 'secrets' },
        'space_guid'              => space.guid,
        'buildpack'               => 'http://example.com/buildpack',
      }
    end
    let(:message) { AppProcessCreateMessage.new(attrs.symbolize_keys) }

    describe 'create' do
      it 'creates an app with a process' do
        process = process_create.create(message)

        expect(process.name).to eq('maria')
        expect(process.space).to eq(space)
        expect(process.environment_json).to eq({ 'key' => 'secrets' })
        expect(process.stack).to eq(Stack.default)
        expect(process.buildpack.url).to eq('http://example.com/buildpack')

        v3_app = process.app
        expect(v3_app.name).to eq('maria')
        expect(v3_app.space).to eq(space)
        expect(v3_app.environment_variables).to eq({ 'key' => 'secrets' })
        expect(v3_app.lifecycle_type).to eq(BuildpackLifecycleDataModel::LIFECYCLE_TYPE)
        expect(v3_app.lifecycle_data.stack).to eq(Stack.default.name)
        expect(v3_app.lifecycle_data.buildpack).to eq('http://example.com/buildpack')
        expect(v3_app.guid).to eq(process.guid)
        
        expect(v3_app.desired_state).to eq(process.state)
      end
    end
  end
end
