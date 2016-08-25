require 'spec_helper'
require 'actions/v2/lifecycle_create'

module VCAP::CloudController
  RSpec.describe V2::LifecycleCreate do
    let(:user) { User.make }
    let(:space) { Space.make }
    let(:stack) { Stack.make(name: 'stacks-on-stacks') }
    let(:app) { AppModel.create(name: 'supscool', space: space) }
    subject(:lifecycle_create) { described_class.new(user.guid, 'user_email') }

    describe 'create' do
      context 'when both a buildpack and stack guid are requested' do
        let(:attrs) do
          {
            'buildpack' => 'http://example.com/buildpack',
            'stack_guid' => stack.guid
          }
        end

        it 'creates a buildpack lifecycle with a stack on the app' do
          lifecycle_create.create(attrs, app)

          app_lifecycle = app.buildpack_lifecycle_data

          expect(app_lifecycle.buildpack).to eq('http://example.com/buildpack')
          expect(app_lifecycle.stack).to eq('stacks-on-stacks')
        end
      end

      context 'when only buildpack is requested' do
        let(:attrs) { { 'buildpack' => 'http://example.com/buildpack' } }

        it 'creates a buildpack lifecycle with a default stack' do
          lifecycle_create.create(attrs, app)

          app_lifecycle = app.buildpack_lifecycle_data

          expect(app_lifecycle.buildpack).to eq('http://example.com/buildpack')
          expect(app_lifecycle.stack).to eq(Stack.default.name)
        end
      end

      context 'when only a stack guid is requested' do
        let(:attrs) { { 'stack_guid' => stack.guid } }

        it 'creates a buildpack lifecycle on the app' do
          lifecycle_create.create(attrs, app)

          app_lifecycle = app.buildpack_lifecycle_data

          expect(app_lifecycle.buildpack).to be_nil
          expect(app_lifecycle.stack).to eq('stacks-on-stacks')
        end

        context 'when the requested stack guid is not found' do
          let(:attrs) { { 'stack_guid' => 'woopsadoodle' } }

          it 'creates a buildpack lifecycle with a default stack' do
            lifecycle_create.create(attrs, app)

            app_lifecycle = app.buildpack_lifecycle_data

            expect(app_lifecycle.buildpack).to be_nil
            expect(app_lifecycle.stack).to eq(Stack.default.name)
          end
        end
      end

      context 'when a docker image is requested' do
        let(:attrs) { { 'docker_image' => 'sups-cool-image:latest' } }

        it 'creates a docker package for the app' do
          lifecycle_create.create(attrs, app)

          package = PackageModel.last

          expect(package.app_guid).to eq(app.guid)
          expect(package.docker_image).to eq('sups-cool-image:latest')
        end
      end
    end
  end
end
