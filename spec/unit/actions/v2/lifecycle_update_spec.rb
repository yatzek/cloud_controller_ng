require 'spec_helper'
require 'actions/v2/lifecycle_update'

module VCAP::CloudController
  RSpec.describe V2::LifecycleUpdate do
    let(:user) { User.make }
    subject(:lifecycle_update) { described_class.new(user.guid, 'user_email') }

    describe 'update' do
      describe 'buildpack lifecycle' do
        context 'stack_guid' do
          let(:attrs) { { 'stack_guid' => Stack.make(name: 'bear-stack').guid } }
          let(:app) { AppFactory.make }
          let(:v3_app) { app.app }

          it 'updates the stack' do
            app_lifecycle = v3_app.lifecycle_data
            app_lifecycle.update(buildpack: nil, stack: 'stacks-on-stack')

            expect(app_lifecycle.stack).to eq('stacks-on-stack')

            lifecycle_update.update(attrs, app)
            expect(app_lifecycle.stack).to eq('bear-stack')
          end

          context 'when the app is already staged' do
            let(:attrs) { { 'stack_guid' => Stack.make(name: 'bear-stack').guid } }
            let(:app) { AppFactory.make(instances: 1, state: 'STARTED') }
            let(:v3_app) { app.app }

            it 'marks the app for re-staging' do
              expect(app.needs_staging?).to eq(false)

              lifecycle_update.update(attrs, app)
              app.reload

              expect(app.needs_staging?).to eq(true)
              expect(app.staged?).to eq(false)
            end
          end

          context 'when the app needs staging' do
            let(:attrs) { { 'stack_guid' => Stack.make(name: 'bear-stack').guid } }
            let(:app) { AppFactory.make( state: 'STARTED') }
            let(:v3_app) { app.app }

            before do
              PackageModel.make(app: v3_app, package_hash: 'some-hash')
              app.reload
            end

            it 'keeps app as needs staging' do
              expect(app.staged?).to eq(false)
              expect(app.needs_staging?).to eq(true)

              lifecycle_update.update(attrs, app)
              app.reload

              expect(app.staged?).to eq(false)
              expect(app.needs_staging?).to eq(true)
            end
          end
        end

        context 'buildpack' do
          let(:attrs) { { 'buildpack' => 'mittens' } }
          let(:app) { AppFactory.make }
          let(:v3_app) { app.app }

          it 'updates the buildpack' do
            app_lifecycle = v3_app.lifecycle_data
            app_lifecycle.update(buildpack: 'kittens')

            expect(app_lifecycle.buildpack).to eq('kittens')
            lifecycle_update.update(attrs, app)
            expect(app_lifecycle.buildpack).to eq('mittens')
          end
        end
      end

      describe 'docker_image' do
        let(:app) { AppFactory.make(app: AppModel.make(:docker), docker_image: 'og-image:latest') }
        let(:v3_app) { app.app }
        let!(:og_package) { app.package }
        let(:attrs) { { 'docker_image' => 'new-image:latest' } }

        it 'creates a new docker package' do
          expect(app.docker_image).not_to eq('new-image:latest')
          lifecycle_update.update(attrs, app)

          expect(app.reload.docker_image).to eq('new-image:latest')
          expect(app.package).not_to eq(og_package)
        end

        context 'when the docker image is requested but is not a change' do
          let(:attrs) { { "docker_image" => 'OG-IMAGE:LATEST' } }

          it 'does not create a new package' do
            expect(app.reload.docker_image).to eq('og-image:latest')

            lifecycle_update.update(attrs, app)

            expect(app.reload.docker_image).to eq('og-image:latest')
            expect(app.package).to eq(og_package)
          end
        end
      end
    end
  end
end
