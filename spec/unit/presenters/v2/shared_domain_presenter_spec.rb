require 'spec_helper'

module CloudController::Presenters::V2
  describe SharedDomainPresenter do
    subject { described_class.new }

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

      let(:space) { Space.make }
      let(:domain) { SharedDomain.make(router_group_guid: 'tcp-group') }
      let(:service_instance) { ManagedServiceInstance.make(:routing, space: space) }

      it 'returns the domain entity and associated urls' do
        expect(subject.entity_hash(controller, domain, opts, depth, parents, orphans)).to eq(
          {
            'name'              => domain.name,
            'router_group_guid' => 'tcp-group',
            'router_group_type' => nil,
            'relationship_key' => 'relationship_value'
          }
        )

        expect(relations_presenter).to have_received(:to_hash).with(controller, domain, opts, depth, parents, orphans)
      end
    end
  end
end
