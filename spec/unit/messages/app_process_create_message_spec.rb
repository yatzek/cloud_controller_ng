require 'spec_helper'
require 'messages/app_process_create_message'

module VCAP::CloudController
  RSpec.describe AppProcessCreateMessage do
    describe 'create from http request' do
      let(:body) do
        {
          'name'                    => 'some-name',
          'environment_json'        => { 'key' => 'secrets' },
          'space_guid'              => 'space-guid',
          'memory'                  => 1024,
          'buildpack'               => 'ruby',
          'instances'               => 1,
          'disk_quota'              => 1024,
          'state'                   => 'STARTED',
          'command'                 => 'be rake',
          'health_check_type'       => 'port',
          'health_check_timeout'    => 60,
          'diego'                   => true,
          'enable_ssh'              => true,
          'docker_credentials_json' => {},
          'ports'                   => [8080],
          'stack_guid'              => 'stack-guid',
          'docker_image'            => 'noimagehere',
          'route_guids'             => ['some-route-guid']
        }
      end

      it 'returns the correct AppProcessCreateMessage' do
        message = AppProcessCreateMessage.create_from_http_request(body)

        expect(message).to be_a(AppProcessCreateMessage)
        expect(message.name).to eq('some-name')
        expect(message.environment_json).to eq({ 'key' => 'secrets' })
        expect(message.space_guid).to eq('space-guid')
        expect(message.memory).to eq(1024)
        expect(message.instances).to eq(1)
        expect(message.disk_quota).to eq(1024)
        expect(message.state).to eq('STARTED')
        expect(message.command).to eq('be rake')
        expect(message.health_check_type).to eq('port')
        expect(message.health_check_timeout).to eq(60)
        expect(message.diego).to eq(true)
        expect(message.enable_ssh).to eq(true)
        expect(message.docker_credentials_json).to eq({})
        expect(message.ports).to eq([8080])
        expect(message.stack_guid).to eq('stack-guid')
        expect(message.docker_image).to eq('noimagehere')
        expect(message.route_guids).to eq(['some-route-guid'])
      end

      it 'converts requested keys to symbols' do
        message = AppProcessCreateMessage.create_from_http_request(body)

        expect(message.requested?(:memory)).to be_truthy
        expect(message.requested?(:instances)).to be_truthy
        expect(message.requested?(:disk_quota)).to be_truthy
      end
    end

    describe 'when unexpected keys are requested' do
      let(:params) { { surprise: 'foo' } }

      it 'is not valid' do
        message = AppProcessCreateMessage.new(params)
        expect(message).not_to be_valid
        expect(message.errors[:base]).to include("Unknown field(s): 'surprise'")
      end
    end

    describe 'validations' do
      let(:buildpack) { 'ruby' }
      let(:disk_quota) { 1000 }
      let(:health_check_type) { 'port' }
      let(:instances) { 1 }
      let(:state) { 'STARTED' }
      let(:credentials) { { docker_user: 'yo', docker_password: 'yup' } }
      let(:ports) { [8080] }
      let(:health_check_timeout) { 60 }
      let(:diego) { true }
      let(:enable_ssh) { true }
      let(:command) { 'be rake' }
      let(:memory) { 1024 }
      let(:route_guids) { ['some-route-guid'] }
      let(:name) { 'some-name' }
      let(:environment_json) { { stuff: 'yup' } }

      let(:body) do
        {
          memory:                  memory,
          name:                    name,
          buildpack:               buildpack,
          instances:               instances,
          disk_quota:              disk_quota,
          state:                   state,
          command:                 command,
          health_check_type:       health_check_type,
          health_check_timeout:    health_check_timeout,
          diego:                   diego,
          enable_ssh:              enable_ssh,
          docker_credentials_json: credentials,
          ports:                   ports,
          route_guids:             route_guids,
          environment_json:        environment_json
        }
      end

      describe 'name' do
        context 'when name is not a string' do
          let(:name) { 32.77 }

          it 'is not valid' do
            message = AppProcessCreateMessage.new(body)

            expect(message).not_to be_valid
            expect(message.errors_on(:name)).to include('must be a string')
          end
        end

        context 'when name is not requested' do
          let(:name) { nil }

          it 'is not valid' do
            message = AppProcessCreateMessage.new(body)

            expect(message).not_to be_valid
            expect(message.errors_on(:name)).to include("can't be blank")
          end
        end
      end

      describe 'environment_json' do
        context 'it is not a hash' do
          let(:environment_json) { 'potato' }

          it 'is not valid' do
            message = AppProcessCreateMessage.new(body)

            expect(message).not_to be_valid
            expect(message.errors_on(:environment_json)).to include('must be a hash')
          end
        end

        context 'when it is nil' do
          let(:environment_json) { nil }

          it 'is valid' do
            message = AppProcessCreateMessage.new(body)

            expect(message).to be_valid
          end
        end
      end

      describe 'buildpack' do
        context 'when it is nil' do
          let(:buildpack) { nil }

          it 'is valid' do
            message = AppProcessCreateMessage.new(body)
            expect(message).to be_valid
          end
        end

        context 'when it is a string' do
          let(:buildpack) { 'http://www.utakos-buildpack.com' }

          it 'is valid' do
            message = AppProcessCreateMessage.new(body)
            expect(message).to be_valid
          end
        end

        context 'when the url is not a string' do
          let(:buildpack) { 1234 }

          it 'is not valid' do
            message = AppProcessCreateMessage.new(body)

            expect(message).not_to be_valid
            expect(message.errors[:buildpack]).to include('must be a string')
          end
        end
      end

      describe 'disk_quota' do
        context 'when disk quota is not an number' do
          let(:disk_quota) { 'im not a number, try and stop me' }

          it 'is not valid' do
            message = AppProcessCreateMessage.new(body)
            expect(message).not_to be_valid
          end
        end

        context 'when disk quota is not an number' do
          let(:disk_quota) { 10.23 }

          it 'is not valid' do
            message = AppProcessCreateMessage.new(body)
            expect(message).not_to be_valid
          end
        end

        context 'when the disk quota is nil' do
          let(:disk_quota) { nil }

          it 'is valid' do
            message = AppProcessCreateMessage.new(body)
            expect(message).to be_valid
          end
        end
      end

      describe 'health_check_type' do
        context 'when the health_check_type is nil' do
          let(:health_check_type) { nil }

          it 'is valid' do
            message = AppProcessCreateMessage.new(body)
            expect(message).to be_valid
          end
        end

        context 'when the health_check_type is not a string' do
          let(:health_check_type) { 12347 }

          it 'is not valid' do
            message = AppProcessCreateMessage.new(body)
            expect(message).not_to be_valid
          end
        end
      end

      describe 'instances' do
        context 'when the instance are not an number' do
          let(:instances) { 'i am not a number, stop me' }

          it 'is not valid' do
            message = AppProcessCreateMessage.new(body)
            expect(message).not_to be_valid
          end
        end

        context 'when the instances are not an integer' do
          let(:instances) { 10.23 }

          it 'is not valid' do
            message = AppProcessCreateMessage.new(body)
            expect(message).not_to be_valid
          end
        end

        context 'when the instances are not a positive integer' do
          let(:instances) { -1 }

          it 'is not valid' do
            message = AppProcessCreateMessage.new(body)
            expect(message).not_to be_valid
          end
        end

        context 'when the instances are nil' do
          let(:instances) { nil }

          it 'is not valid' do
            message = AppProcessCreateMessage.new(body)
            expect(message).to be_valid
          end
        end
      end

      describe 'state' do
        context 'when state is not a string' do
          let(:state) { 2 }

          it 'is not valid' do
            message = AppProcessCreateMessage.new(body)
            expect(message).not_to be_valid
          end
        end

        context 'when the state is nil' do
          let(:state) { nil }

          it 'is valid' do
            message = AppProcessCreateMessage.new(body)
            expect(message).to be_valid
          end
        end
      end

      describe 'docker credentials' do
        context 'when the credentials are not a hash' do
          let(:credentials) { 'i am not hash, what now?' }

          it 'is not valid' do
            message = AppProcessCreateMessage.new(body)
            expect(message).not_to be_valid
          end
        end

        context 'when the credentials provided are empty' do
          let(:credentials) { {} }

          it 'is valid' do
            message = AppProcessCreateMessage.new(body)
            expect(message).to be_valid
          end
        end

        context 'when the credentials are nil' do
          let(:credentials) { nil }

          it 'is valid' do
            message = AppProcessCreateMessage.new(body)
            expect(message).to be_valid
          end
        end
      end

      describe 'ports' do
        context 'when the ports are not an array' do
          let(:ports) { 'i am not array, what now?' }

          it 'is not valid' do
            message = AppProcessCreateMessage.new(body)
            expect(message).not_to be_valid
          end
        end

        context 'when the ports are not an array of integers' do
          let(:ports) { ['if this is wrong i dont wanna be right'] }

          it 'is not valid' do
            message = AppProcessCreateMessage.new(body)
            expect(message).not_to be_valid
          end
        end

        context 'when the ports are nil' do
          let(:ports) { nil }

          it 'is valid' do
            message = AppProcessCreateMessage.new(body)
            expect(message).to be_valid
          end
        end
      end

      describe 'health_check_timeout' do
        context 'when health_check_timeout is not number' do
          let(:health_check_timeout) { 'numbers are people too' }

          it 'is not valid' do
            message = AppProcessCreateMessage.create_from_http_request(body)
            expect(message).not_to be_valid
          end
        end

        context 'when health_check_timeout is not an integer' do
          let(:health_check_timeout) { 10.45 }

          it 'is not valid' do
            message = AppProcessCreateMessage.create_from_http_request(body)
            expect(message).not_to be_valid
          end
        end

        context 'when health_check_timeout is nil' do
          let(:health_check_timeout) { nil }

          it 'is valid' do
            message = AppProcessCreateMessage.create_from_http_request(body)
            expect(message).to be_valid
          end
        end
      end

      describe 'route_guids' do
        context 'when they are not an array' do
          let(:route_guids) { 'i am not array, what now?' }

          it 'is not valid' do
            message = AppProcessCreateMessage.new(body)
            expect(message).not_to be_valid
          end
        end

        context 'when they are not an array of guids' do
          let(:route_guids) { [1, 'if this is wrong i dont wanna be right'] }

          it 'is not valid' do
            message = AppProcessCreateMessage.new(body)
            expect(message).not_to be_valid
          end
        end

        context 'when they are nil' do
          let(:route_guids) { nil }

          it 'is valid' do
            message = AppProcessCreateMessage.new(body)
            expect(message).to be_valid
          end
        end
      end

      describe 'diego' do
        context 'is not a boolean' do
          let(:diego) { 'no boolean here' }

          it 'is not valid' do
            message = AppProcessCreateMessage.new(body)
            expect(message).not_to be_valid
          end
        end

        context 'when it is nil' do
          let(:diego) { nil }

          it 'is valid' do
            message = AppProcessCreateMessage.new(body)
            expect(message).to be_valid
          end
        end
      end

      describe 'enable_ssh' do
        context 'is not a boolean' do
          let(:enable_ssh) { 'no boolean here' }

          it 'is not valid' do
            message = AppProcessCreateMessage.new(body)
            expect(message).not_to be_valid
          end
        end

        context 'when it is nil' do
          let(:enable_ssh) { nil }

          it 'is valid' do
            message = AppProcessCreateMessage.new(body)
            expect(message).to be_valid
          end
        end
      end

      describe 'command' do
        context 'is a not a string' do
          let(:command) { 123 }

          it 'is not valid' do
            message = AppProcessCreateMessage.new(body)
            expect(message).not_to be_valid
          end
        end

        context 'when it is nil' do
          let(:command) { nil }

          it 'is valid' do
            message = AppProcessCreateMessage.new(body)
            expect(message).to be_valid
          end
        end
      end

      describe 'memory' do
        context 'when it is not an number' do
          let(:memory) { 'im not a number, try and stop me' }

          it 'is not valid' do
            message = AppProcessCreateMessage.new(body)
            expect(message).not_to be_valid
          end
        end

        context 'when it is not an number' do
          let(:memory) { 10.23 }

          it 'is not valid' do
            message = AppProcessCreateMessage.new(body)
            expect(message).not_to be_valid
          end
        end

        context 'when the it is nil' do
          let(:memory) { nil }

          it 'is valid' do
            message = AppProcessCreateMessage.new(body)
            expect(message).to be_valid
          end
        end
      end
    end

    describe '#lifecycle' do
      context 'when both buildpack and stack guid are requested' do
        stack = Stack.make(name: 'astack')
        let(:params) { { buildpack: 'mybuildpackyo', stack_guid: stack.guid } }

        it 'returns the correct lifecycle object' do
          message         = AppProcessCreateMessage.new(params)
          expected_result = {
            lifecycle: {
              type: 'buildpack',
              data: {
                buildpack: 'mybuildpackyo',
                stack: 'astack'
              }
            }
          }

          expect(message.lifecycle).to eq(expected_result)
        end
      end

      context 'when buildpack is requested' do
        let(:params) { { buildpack: 'mybuildpackyo' } }

        it 'returns the correct lifecycle object' do
          message         = AppProcessCreateMessage.new(params)
          expected_result = {
            lifecycle: {
              type: 'buildpack',
              data: {
                buildpack: 'mybuildpackyo',
                stack: nil
              }
            }
          }

          expect(message.lifecycle).to eq(expected_result)
        end
      end

      context 'when a stack guid is requested' do
        stack = Stack.make(name: 'mystack')
        let(:params) { { stack_guid: stack.guid } }

        it 'returns the correct lifecycle object' do
          message         = AppProcessCreateMessage.new(params)
          expected_result = {
            lifecycle: {
              type: 'buildpack',
              data: {
                buildpack: nil,
                stack: 'mystack'
              }
            }
          }

          expect(message.lifecycle).to eq(expected_result)
        end
      end

      context 'when a docker image is requested' do
        let(:params) { { docker_image: 'dockerimageyeah' } }

        it 'returns the correct lifecycle object' do
          message         = AppProcessCreateMessage.new(params)
          expected_result = {
            lifecycle: {
              type: 'docker',
              data: {
                image: 'dockerimageyeah',
              }
            }
          }

          expect(message.lifecycle).to eq(expected_result)
        end
      end
    end
  end
end