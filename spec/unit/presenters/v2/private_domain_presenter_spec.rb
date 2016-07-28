require 'spec_helper'

module CloudController::Presenters::V2
  RSpec.describe PrivateDomainPresenter do
    subject { described_class.new }

    let(:controller) { 'controller' }
    let(:domain) { 'domain' }
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
      let(:domain) { VCAP::CloudController::PrivateDomain.make(owning_organization: space.organization) }

      it 'returns the domain and the guid of the org that owns it' do
        expect(subject.entity_hash(controller, domain, opts, depth, parents, orphans)).to eq(
          {
            'name'                      => domain.name,
            'owning_organization_guid'  => space.organization.guid,
            'relationship_key'          => 'relationship_value'
          }
        )

        expect(relations_presenter).to have_received(:to_hash).with(controller, domain, opts, depth, parents, orphans)
      end
    end
  end
end
