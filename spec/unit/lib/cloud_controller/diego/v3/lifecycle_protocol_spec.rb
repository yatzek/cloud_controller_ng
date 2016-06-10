require 'spec_helper'
require 'cloud_controller/diego/v3/lifecycle_protocol'

module ::Diego
  module V3
    describe LifecycleProtocol do
      describe '.protocol_for_type' do
        subject(:protocol) { LifecycleProtocol.protocol_for_type(type) }

        context 'with BUILDPACK' do
          let(:type) { Lifecycles::BUILDPACK }

          it 'returns a buildpack lifecycle protocol' do
            expect(protocol).to be_a(::Diego::V3::Buildpack::LifecycleProtocol)
          end
        end

        context 'with DOCKER' do
          let(:type) { Lifecycles::DOCKER }

          it 'returns a buildpack lifecycle protocol' do
            expect(protocol).to be_a(::Diego::V3::Docker::LifecycleProtocol)
          end
        end
      end
    end
  end
end
